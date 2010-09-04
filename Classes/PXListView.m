//
//  PXListView.m
//  PXListView
//
//  Created by Alex Rozanski on 29/05/2010.
//  Copyright 2010 Alex Rozanski. http://perspx.com. All rights reserved.
//

#import "PXListView.h"
#import "PXListView+Private.h"

#import <iso646.h>

#import "PXListViewCell.h"
#import "PXListViewCell+Private.h"

//Apple sadly doesn't provide CGFloat variants of these:
#if CGFLOAT_IS_DOUBLE
#define CGFLOATABS(n)	fabs(n)
#else
#define CGFLOATABS(n)	fabsf(n)
#endif

static PXIsDragStartResult	PXIsDragStart( NSEvent *startEvent, NSTimeInterval theTimeout )
{
	if( theTimeout == 0.0 )
		theTimeout = 1.5;
	
	NSPoint			startPos = [startEvent locationInWindow];
	NSTimeInterval	startTime = [NSDate timeIntervalSinceReferenceDate];
	NSDate*			expireTime = [NSDate dateWithTimeIntervalSinceReferenceDate: startTime +theTimeout];
	
	NSAutoreleasePool	*pool = nil;
	while( ([expireTime timeIntervalSinceReferenceDate] -[NSDate timeIntervalSinceReferenceDate]) > 0 )
	{
		[pool release];
		pool = [[NSAutoreleasePool alloc] init];
		
		NSEvent*	currEvent = [NSApp nextEventMatchingMask: NSLeftMouseUpMask | NSRightMouseUpMask | NSOtherMouseUpMask
								 | NSLeftMouseDraggedMask | NSRightMouseDraggedMask | NSOtherMouseDraggedMask
												untilDate: expireTime inMode: NSEventTrackingRunLoopMode dequeue: YES];
		if( currEvent )
		{
			switch( [currEvent type] )
			{
				case NSLeftMouseUp:
				case NSRightMouseUp:
				case NSOtherMouseUp:
				{
					[pool release];
					return PXIsDragStartMouseReleased;	// Mouse released within the wait time.
					break;
				}
					
				case NSLeftMouseDragged:
				case NSRightMouseDragged:
				case NSOtherMouseDragged:
				{
					NSPoint	newPos = [currEvent locationInWindow];
					CGFloat	xMouseMovement = CGFLOATABS(newPos.x -startPos.x),
					yMouseMovement = CGFLOATABS(newPos.y -startPos.y);
					if( xMouseMovement > 2 or yMouseMovement > 2 )
					{
						[pool release];
						return (xMouseMovement > yMouseMovement) ? PXIsDragStartMouseMovedHorizontally : PXIsDragStartMouseMovedVertically;	// Mouse moved within the wait time, probably a drag!
					}
					break;
				}
			}
		}
		
	}
	
	[pool release];
	return PXIsDragStartTimedOut;	// If they held the mouse that long, they probably wanna drag.
}

@implementation PXListView

@synthesize delegate = _delegate;
@synthesize cellSpacing = _cellSpacing;
@synthesize allowsMultipleSelection = _allowsMultipleSelection;
@synthesize allowsEmptySelection = _allowsEmptySelection;
@synthesize verticalMotionCanBeginDrag = _verticalMotionCanBeginDrag;

#pragma mark -
#pragma mark Init/Dealloc

- (id)initWithFrame:(NSRect)theFrame
{
	if((self = [super initWithFrame:theFrame]))
	{
		_reusableCells = [[NSMutableArray alloc] init];
		_visibleCells = [[NSMutableArray alloc] init];
		_selectedRows = [[NSMutableIndexSet alloc] init];
	}
	
	return self;
}

- (id)initWithCoder:(NSCoder*)decoder
{
	if((self = [super initWithCoder:decoder]))
	{
		_reusableCells = [[NSMutableArray alloc] init];
		_visibleCells = [[NSMutableArray alloc] init];
		_selectedRows = [[NSMutableIndexSet alloc] init];
	}
	
	return self;
}

- (void)awakeFromNib
{
	// Subscribe to scrolling notification:
	NSClipView *contentView = [self contentView];
	[contentView setPostsBoundsChangedNotifications: YES];
	
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(contentViewBoundsDidChange:)
												 name:NSViewBoundsDidChangeNotification
											   object:contentView];
	
	// Tag ourselves onto the document view:
	[[self documentView] setListView:self];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[_reusableCells release], _reusableCells = nil;
	[_visibleCells release], _visibleCells = nil;
	[_selectedRows release], _selectedRows = nil;
	
	[super dealloc];
}

#pragma mark -
#pragma mark Data Handling

- (void)reloadData
{
	id <PXListViewDelegate> delegate = [self delegate];
	
	//Move all visible cells to the reusable cells array
	NSUInteger numCells = [_visibleCells count];
	for (NSUInteger i = 0; i < numCells; i++) {
		PXListViewCell *cell = [_visibleCells objectAtIndex:i];
		[_reusableCells addObject:cell];
		[cell setHidden:YES];
	}
	
	[_visibleCells removeAllObjects];
	free(_cellYOffsets);
	[_selectedRows removeAllIndexes];

	if([delegate conformsToProtocol:@protocol(PXListViewDelegate)])
	{
		_numberOfRows = [delegate numberOfRowsInListView:self];
		[self cacheCellLayout];
		
		NSRange visibleRange = [self visibleRange];
		_currentRange = visibleRange;
		[self addCellsFromVisibleRange];
		
		[self layoutCells];
	}
}


- (void)setSelectedRow:(NSUInteger)row
{
	[self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection: NO];
}


- (NSUInteger)selectedRow
{
	if( [_selectedRows count] == 1 ) {
		return [_selectedRows firstIndex];
	}
	else {
		//This gives -1 for 0 selected items (backwards compatible) *and* for multiple selections.
		return NSUIntegerMax;
	}
}


- (void)setSelectedRows:(NSIndexSet *)rowIndexes
{
	[self selectRowIndexes:rowIndexes byExtendingSelection:NO];
}


- (NSIndexSet*)selectedRows
{
	return _selectedRows;	// +++ Copy/autorelease?
}


- (void)selectRowIndexes:(NSIndexSet*)rows byExtendingSelection:(BOOL)shouldExtend
{
	if(!shouldExtend) {
		[self deselectRowIndexes: _selectedRows];	// +++ Optimize. Could intersect sets and only deselect what's needed.
	}
	
	[_selectedRows addIndexes:rows];	// _selectedRows is empty if !doExtend, because we just deselected all.

	NSArray *newSelectedCells = [self visibleCellsForRowIndexes:rows];
	for(PXListViewCell *newSelectedCell in newSelectedCells)
	{
		[newSelectedCell setNeedsDisplay: YES];
	}
}


- (void)deselectRowIndexes:(NSIndexSet*)rows
{
	NSArray *oldSelectedCells = [self visibleCellsForRowIndexes:rows];
	[_selectedRows removeIndexes:rows];
	
	for( PXListViewCell *oldSelectedCell in oldSelectedCells )
	{
		[oldSelectedCell setNeedsDisplay: YES];
	}
}


- (void)deselectRows
{
	[self deselectRowIndexes: _selectedRows];
}


- (NSUInteger)numberOfRows
{
	return _numberOfRows;
}

#pragma mark -
#pragma mark Cell Handling

- (void)enqueueCell:(PXListViewCell*)cell
{
	[_reusableCells addObject:cell];
	[_visibleCells removeObject:cell];
	[cell setHidden: YES];
}

- (PXListViewCell*)dequeueCellWithReusableIdentifier:(NSString*)identifier
{
	if([_reusableCells count]==0) {
		return nil;
	}
	
	//Search backwards looking for a match since removing from end of array is generally quicker
	// Tom: Somehow i was getting <0 here, because i>=0 is always true for unsigned integers. Temporarily made this an integer.
	// Tom: This was only a bug for lists using multiple identifiers for its cells.
	// Tom: NSInteger shouldn't be a problem here - nobody will have more than 2.1 billion active cells.
	for(NSInteger i = [_reusableCells count]-1; i>=0;i--)
	{
		PXListViewCell *cell = [_reusableCells objectAtIndex:i];
		
		if([[cell reusableIdentifier] isEqualToString:identifier])
		{
			//Make sure it doesn't get dealloc'd early
			[cell retain];            
			[_reusableCells removeObjectAtIndex:i];
			[cell prepareForReuse];
			return [cell autorelease];
		}
	}
	
	return nil;
}

- (NSRange)visibleRange
{
	NSRect visibleRect = [[self contentView] documentVisibleRect];
	NSUInteger startRow = NSUIntegerMax;
	NSUInteger endRow = NSUIntegerMax;
	
	BOOL inRange = NO;
	for(NSUInteger i = 0; i < _numberOfRows; i++)
	{
		if(NSIntersectsRect([self rectOfRow:i], visibleRect))
		{
			if(startRow == NSUIntegerMax)
			{
				startRow = i;
				inRange = YES;
			}
		}
		else
		{
			if(inRange)
			{
				endRow = i;
				break;
			}
		}
	}
	
	if(endRow == NSUIntegerMax)
	{
		endRow = _numberOfRows; 
	}
	
	return NSMakeRange(startRow, endRow-startRow);
}

- (PXListViewCell*)visibleCellForRow:(NSUInteger)row
{
	PXListViewCell *outCell = nil;
	
	for(PXListViewCell* cell in _visibleCells)
	{
		if([cell row] == row)
		{
			outCell = cell;
			break;
		}
	}
	
	return outCell;
}

- (NSArray*)visibleCellsForRowIndexes:(NSIndexSet*)rows
{
	NSMutableArray * theCells = [NSMutableArray array];
	
	for(PXListViewCell* cell in _visibleCells)
	{
		if([rows containsIndex:[cell row]])
		{
			[theCells addObject: cell];
		}
	}
	
	return theCells;
}

- (void)addCellsFromVisibleRange
{
	id <PXListViewDelegate> delegate = [self delegate];
	
	if([delegate conformsToProtocol:@protocol(PXListViewDelegate)])
	{
		NSRange visibleRange = [self visibleRange];
		
		for(NSUInteger i = visibleRange.location; i < NSMaxRange(visibleRange); i++)
		{
			id cell = [delegate listView:self cellForRow:i];
			[_visibleCells addObject:cell];
			[self addNewVisibleCell:cell atRow:i];
		}
	}
}

- (void)updateCells
{	
	//Resizing all the cells in live resize is computationally pretty expensive; however make this a property?
	if(_inLiveResize) {
		return;
	}
	
	NSRange visibleRange = [self visibleRange];
	NSRange intersectionRange = NSIntersectionRange(visibleRange, _currentRange);
	
	//Have the cells we need to display actually changed?
	if((visibleRange.location == _currentRange.location) && (NSMaxRange(visibleRange) == NSMaxRange(_currentRange))) {
		return;
	}
	
	if((intersectionRange.location == 0) && (intersectionRange.length == 0))
	{
		//We'll have to rebuild all the cells
		[_reusableCells addObjectsFromArray:_visibleCells];
		[_visibleCells removeAllObjects];
		[[self documentView] setSubviews:[NSArray array]];
		[self addCellsFromVisibleRange];
	}
	else
	{
		if( visibleRange.location < _currentRange.location ) //Add top 
		{
			for( NSUInteger i = _currentRange.location; i > visibleRange.location; i-- )
			{
				NSUInteger newRow = i -1;
				PXListViewCell *cell = [[self delegate] listView:self cellForRow:newRow];
				[_visibleCells insertObject: cell atIndex: 0];
				[self addNewVisibleCell:cell atRow:newRow];
			}
		}
		else if( visibleRange.location > _currentRange.location ) //Remove top
		{
			for( NSUInteger i = visibleRange.location; i > _currentRange.location; i-- )
			{
				PXListViewCell *firstCell = [_visibleCells objectAtIndex:0];
				[self enqueueCell:firstCell];
			}
		}
		
		if( NSMaxRange(visibleRange) > NSMaxRange(_currentRange) ) //Add bottom
		{
			for( NSUInteger i = NSMaxRange(_currentRange); i < NSMaxRange(visibleRange); i++ )
			{
				NSInteger newRow = i;
				PXListViewCell *cell = [[self delegate] listView:self cellForRow:newRow];
				[_visibleCells addObject:cell];
				[self addNewVisibleCell:cell atRow:newRow];
			}
		}
		else if(NSMaxRange(visibleRange)<NSMaxRange(_currentRange)) //Remove bottom
		{
			for( NSUInteger i = NSMaxRange(_currentRange); i > NSMaxRange(visibleRange); i-- )
			{
				PXListViewCell *lastCell = [_visibleCells lastObject];
				[self enqueueCell:lastCell];
			}
		}
	}
	
	#if DEBUG
	PXLog(@"No of cells in view hierarchy: %d", [_visibleCells count]);
	#endif
	
	_currentRange = visibleRange;
}

- (void)addNewVisibleCell:(PXListViewCell*)cell atRow:(NSUInteger)row
{
	[[self documentView] addSubview:cell];
	[cell setListView:self];
	[cell setRow:row];
	[self layoutCell:cell];
	[cell setHidden: NO];
}


- (BOOL)	attemptDragWithMouseDown: (NSEvent*)theEvent inCell: (PXListViewCell*)theCell
{
	PXIsDragStartResult	dragResult = PXIsDragStart( theEvent, 0.0 );
	if( dragResult != PXIsDragStartMouseReleased /*&& (_verticalMotionCanBeginDrag || dragResult != PXIsDragStartMouseMovedVertically)*/ )	// Was a drag, not a click? Cool!
	{
		NSPoint			dragImageOffset = NSZeroPoint;
		NSImage			*dragImage = [self dragImageForRowsWithIndexes: _selectedRows event: theEvent clickedCell: theCell offset: &dragImageOffset];
		NSPasteboard	*dragPasteboard = [NSPasteboard pasteboardWithUniqueName];
		
		if( [_delegate respondsToSelector: @selector(listView:writeRowsWithIndexes:toPasteboard:)]
			and [_delegate listView: self writeRowsWithIndexes: _selectedRows toPasteboard: dragPasteboard] )
		{
			[theCell dragImage: dragImage at: dragImageOffset offset: NSZeroSize event: theEvent
						pasteboard: dragPasteboard source: self slideBack: YES];
			
			return YES;
		}
	}
	
	return NO;
}

- (void)	handleMouseDown: (NSEvent*)theEvent	inCell: (PXListViewCell*)theCell // Central funnel for cell clicks so cells don't have to know about multi-selection, modifiers etc.
{
	// theEvent is NIL if we get a "press" action from accessibility. In that case, try to toggle, so users can selectively turn on/off an item.
	
	BOOL		tryDraggingAgain = YES;
	BOOL		shouldToggle = theEvent == nil || ([theEvent modifierFlags] & NSCommandKeyMask) or ([theEvent modifierFlags] & NSShiftKeyMask);	// +++ Shift should really be a continuous selection.
	BOOL		isSelected = [_selectedRows containsIndex: [theCell row]];
	NSIndexSet	*clickedIndexSet = [NSIndexSet indexSetWithIndex: [theCell row]];
	
	// If a cell is already selected, we can drag it out, in which case we shouldn't toggle it:
	if( theEvent and isSelected and [self attemptDragWithMouseDown: theEvent inCell: theCell] )
		return;
	
	if( _allowsMultipleSelection )
	{
		if( isSelected && shouldToggle )
		{
			if( [_selectedRows count] == 1 && !_allowsEmptySelection )
				return;
			[self deselectRowIndexes: clickedIndexSet];
		}
		else if( !isSelected && shouldToggle )
			[self selectRowIndexes: clickedIndexSet byExtendingSelection: YES];
		else if( !isSelected && !shouldToggle )
			[self selectRowIndexes: clickedIndexSet byExtendingSelection: NO];
		else if( isSelected && !shouldToggle && [_selectedRows count] != 1 )
		{
			[self selectRowIndexes: clickedIndexSet byExtendingSelection: NO];
			tryDraggingAgain = NO;
		}
	}
	else if( shouldToggle && _allowsEmptySelection )
	{
		if( isSelected )
		{
			[self deselectRowIndexes: clickedIndexSet];
			tryDraggingAgain = NO;
		}
		else
			[self selectRowIndexes: clickedIndexSet byExtendingSelection: NO];
	}
	else
	{
		[self selectRowIndexes: clickedIndexSet byExtendingSelection: NO];
	}
	
	// If a user selects a cell, they need to be able to drag it off right away, so check for that case here:
	if( tryDraggingAgain && theEvent and [_selectedRows containsIndex: [theCell row]] )
		[self attemptDragWithMouseDown: theEvent inCell: theCell];
}


- (void)	handleMouseDownOutsideCells: (NSEvent*)theEvent
{
#pragma unused(theEvent)
	if( _allowsEmptySelection )
		[self deselectRows];
	else if( _numberOfRows > 1 )
	{
		NSUInteger	idx = 0;
		NSPoint		pos = [self convertPoint: [theEvent locationInWindow] fromView: nil];
		for( NSUInteger x = 0; x < _numberOfRows; x++ )
		{
			if( _cellYOffsets[x] > pos.y )
				break;
			
			idx = x;
		}
		
		[self setSelectedRow: idx];
	}
}

#pragma mark -
#pragma mark Keyboard Handling

- (BOOL)canBecomeKeyView
{
	return YES;
}


- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (BOOL)becomeFirstResponder
{
	return YES;
}


- (BOOL)resignFirstResponder
{
	return YES;
}


- (void)keyDown:(NSEvent *)theEvent
{
	[self interpretKeyEvents: [NSArray arrayWithObjects: theEvent, nil]];
}


-(void)	moveUp:(id)sender
{
#pragma unused(sender)
	NSUInteger		newSelectedRow = [_selectedRows firstIndex];
	if( [_selectedRows count] == 0 )
		newSelectedRow = _numberOfRows -1;	// NSTableView defaults to selecting last row for up-arrow w/o selection.
	else
	{
		if( newSelectedRow > 0 )
			newSelectedRow -= 1;
	}
	
	[self setSelectedRow: newSelectedRow];
	[self scrollRowToVisible: newSelectedRow];
}


-(void)	moveDown:(id)sender
{
#pragma unused(sender)
	NSUInteger		newSelectedRow = [_selectedRows lastIndex];
	if( [_selectedRows count] == 0 )
		newSelectedRow = 0;	// NSTableView defaults to selecting first row for down-arrow w/o selection.
	else
	{
		if( newSelectedRow < (_numberOfRows -1) )
			newSelectedRow += 1;
	}
	
	[self setSelectedRow: newSelectedRow];
	[self scrollRowToVisible: newSelectedRow];
}


-(BOOL)	validateMenuItem: (NSMenuItem *)menuItem
{
	if( [menuItem action] == @selector(selectAll:) )
	{
		return _allowsMultipleSelection && [_selectedRows count] != _numberOfRows;	// No "select all" if everything's already selected or we can only select one row.
	}
	else if( [menuItem action] == @selector(deselectAll:) )
	{
		return _allowsEmptySelection && [_selectedRows count] != 0;	// No "deselect all" if nothing's selected or we must have at least one row selected.
	}
	else
		return NO;
}


-(void)	selectAll: (id)sender
{
#pragma unused(sender)
	if( _allowsMultipleSelection )
	{
		[self setSelectedRows: [NSIndexSet indexSetWithIndexesInRange: NSMakeRange(0, _numberOfRows)]];
	}
}



-(void)	deselectAll: (id)sender
{
#pragma unused(sender)
	if( _allowsMultipleSelection )
	{
		[self setSelectedRows: [NSIndexSet indexSetWithIndexesInRange: NSMakeRange(0, _numberOfRows)]];
	}
}


#pragma mark -
#pragma mark Layout

- (NSRect)contentViewRect
{
	NSRect frame = [self frame];
	NSSize frameSize = NSMakeSize(NSWidth(frame), NSHeight(frame));
	BOOL hasVertScroller = NSHeight(frame) < _totalHeight;
	NSSize availableSize = [[self class] contentSizeForFrameSize:frameSize
										   hasHorizontalScroller:NO
											 hasVerticalScroller:hasVertScroller
													  borderType:[self borderType]];
	
	return NSMakeRect(0.0f, 0.0f, availableSize.width, availableSize.height);
}

- (NSRect)rectOfRow:(NSUInteger)row
{
	id <PXListViewDelegate> delegate = [self delegate];
	
	if([delegate conformsToProtocol:@protocol(PXListViewDelegate)])
	{
		NSRect contentViewRect = [self contentViewRect];
		CGFloat rowHeight = [delegate listView:self heightOfRow:row];
		
		return NSMakeRect(0.0f, _cellYOffsets[row], NSWidth(contentViewRect), rowHeight);
	}
	
	return NSZeroRect;
}

- (void)cacheCellLayout
{
	id <PXListViewDelegate> delegate = [self delegate];
	
	if([delegate conformsToProtocol:@protocol(PXListViewDelegate)])
	{
		CGFloat totalHeight = 0;
		
		//Allocate the offset caching array
		_cellYOffsets = (CGFloat*)malloc(sizeof(CGFloat)*_numberOfRows);
		
		for( NSUInteger i = 0; i < _numberOfRows; i++ )
		{
			_cellYOffsets[i] = totalHeight;
			CGFloat cellHeight = [delegate listView:self heightOfRow:i];
			
			totalHeight += cellHeight +[self cellSpacing];
		}
		
		_totalHeight = totalHeight;
		
		NSRect bounds = [self bounds];
		CGFloat documentHeight = _totalHeight>NSHeight(bounds)?_totalHeight: (NSHeight(bounds) -2);
		
		[[self documentView] setFrame:NSMakeRect(0.0f, 0.0f, NSWidth([self contentViewRect]), documentHeight)];
	}
}

- (void)layoutCells
{	
	//Set the frames of the cells
	for(id cell in _visibleCells) {
		NSInteger row = [cell row];
		[cell setFrame:[self rectOfRow:row]];
	}
	
	NSRect bounds = [self bounds];
	CGFloat documentHeight = _totalHeight>NSHeight(bounds)?_totalHeight: (NSHeight(bounds) -2);
	
	//Set the new height of the document view
	[[self documentView] setFrame:NSMakeRect(0.0f, 0.0f, NSWidth([self contentViewRect]), documentHeight)];
}

- (void)layoutCell:(PXListViewCell*)cell
{
	NSInteger row = [cell row];
	[cell setFrame:[self rectOfRow:row]];
}

- (void)resizeWithOldSuperviewSize:(NSSize)oldBoundsSize
{
	//If our frame is autosized (not dragged using the sizing handle), we can handle this
	//message to resize the visible cells
	[super resizeWithOldSuperviewSize:oldBoundsSize];
	
	if(!_inLiveResize) {
		[_visibleCells removeAllObjects];
		[[self documentView] setSubviews:[NSArray array]];
		
		[self cacheCellLayout];
		[self addCellsFromVisibleRange];
		
		_currentRange = [self visibleRange];
	}
}

#pragma mark -
#pragma mark Scrolling

- (void)contentViewBoundsDidChange:(NSNotification *)notification
{
#pragma unused(notification)
	[self updateCells];
}


- (void)scrollRowToVisible: (NSUInteger)row
{
	if(row >= _numberOfRows)
		return;
	
	NSRect rowRect = [self rectOfRow: row];
	NSPoint	newScrollPoint = [[self contentView] constrainScrollPoint:rowRect.origin];
	
	// +++ Use minimal scroll necessary. Right now it forces the selection to upper left of window.
	
	[[self contentView] scrollToPoint: newScrollPoint];
	[self reflectScrolledClipView: [self contentView]];
}


#pragma mark -
#pragma mark Drag and Drop

-(NSImage*)	dragImageForRowsWithIndexes: (NSIndexSet *)dragRows event: (NSEvent*)dragEvent clickedCell: (PXListViewCell*)clickedCell offset: (NSPointPointer)dragImageOffset
{
#pragma unused(dragEvent)
	CGFloat		minX = CGFLOAT_MAX, maxX = CGFLOAT_MIN,
				minY = CGFLOAT_MAX, maxY = CGFLOAT_MIN;
	NSPoint		localMouse = [self convertPoint: NSZeroPoint fromView: clickedCell];
	localMouse.y += [self documentVisibleRect].origin.y;
	
	// Determine how large an image we'll need to hold all cells, with their
	//	*unclipped* rectangles:
	for( PXListViewCell* currCell in _visibleCells )
	{
		NSUInteger		currRow = [currCell row];
		if( [dragRows containsIndex: currRow] )
		{
			NSRect		rowRect = [self rectOfRow: currRow];
			if( rowRect.origin.x < minX )
				minX = rowRect.origin.x;
			if( rowRect.origin.y < minY )
				minY = rowRect.origin.y;
			if( NSMaxX(rowRect) > maxX )
				maxX = NSMaxX(rowRect);
			if( NSMaxY(rowRect) > maxY )
				maxY = NSMaxY(rowRect);
		}
	}
	
	// Now draw all cells into the image at the proper relative position:
	NSSize		imageSize = NSMakeSize( maxX -minX, maxY -minY);
	NSImage*	dragImage = [[[NSImage alloc] initWithSize: imageSize] autorelease];
	
	[dragImage lockFocus];
		
		for( PXListViewCell* currCell in _visibleCells )
		{
			NSUInteger		currRow = [currCell row];
			if( [dragRows containsIndex: currRow] )
			{ 
				NSRect				rowRect = [self rectOfRow: currRow];
				NSBitmapImageRep*	bir = [currCell bitmapImageRepForCachingDisplayInRect: [currCell bounds]];
				[currCell cacheDisplayInRect: [currCell bounds] toBitmapImageRep: bir];
				NSPoint				thePos = NSMakePoint( rowRect.origin.x -minX, rowRect.origin.y -minY);
				thePos.y = imageSize.height -(thePos.y +rowRect.size.height);	// Document view is flipped, so flip the coordinates before drawing into image, or the list items will be reversed.
				[bir drawAtPoint: thePos];
			}
		}
		
	[dragImage unlockFocus];
	
	// Give caller the right offset so the image ends up right atop the actual views:
	if( dragImageOffset )
	{
		dragImageOffset->x = -(localMouse.x -minX);
		dragImageOffset->y = (localMouse.y -minY) -imageSize.height;
	}
	
	return dragImage;
}


-(void)	setShowsDropHighlight: (BOOL)inState
{
	[[self documentView] setDropHighlight: (inState ? PXListViewDropOn : PXListViewDropNowhere)];
}


-(NSUInteger)	indexOfRowAtPoint: (NSPoint)pos returningProposedDropHighlight: (PXListViewDropHighlight*)outDropHighlight
{
	PXLog( @"====================" );
	*outDropHighlight = PXListViewDropOn;
	
	if( _numberOfRows > 0 )
	{
		NSUInteger	idx = 0;
		for( NSUInteger x = 0; x < _numberOfRows; x++ )
		{
			if( _cellYOffsets[x] > pos.y )
			{
				PXLog( @"cellYOffset[%ld] = %f > %f", x, _cellYOffsets[x], pos.y );
				break;
			}
			
			idx = x;
		}
		
		PXLog( @"idx = %ld", idx );
		
		CGFloat		cellHeight = 0,
					cellOffset = 0,
					nextCellOffset = 0;
		if( (idx +1) < _numberOfRows )
		{
			cellOffset = _cellYOffsets[idx];
			nextCellOffset = _cellYOffsets[idx+1];
			cellHeight = nextCellOffset -cellOffset;
			if( cellHeight < 0 )
				PXLog( @"Urk. (1)" );
		}
		else if( idx < _numberOfRows && _numberOfRows > 0 )	// drag is somewhere close to or beyond end of list.
		{
			PXListViewCell*	theCell = [self visibleCellForRow: idx];
			cellHeight = [theCell frame].size.height;
			cellOffset = [theCell frame].origin.y;
			nextCellOffset = cellOffset +cellHeight;
			if( cellHeight < 0 )
				PXLog( @"Urk. (2)" );
		}
		else if( idx >= _numberOfRows && _numberOfRows > 0 )	// drag is somewhere close to or beyond end of list.
		{
			cellHeight = 0;
			cellOffset = [[self documentView] frame].size.height;
			nextCellOffset = cellOffset;
			idx = NSUIntegerMax;
			if( cellHeight < 0 )
				PXLog( @"Urk. (3)" );
		}

		PXLog( @"cellHeight = %f", cellHeight );
		if( pos.y < (cellOffset +(cellHeight / 6.0)) )
		{
			*outDropHighlight = PXListViewDropAbove;
			PXLog( @"*** ABOVE %ld", idx );
		}
		else if( pos.y > (nextCellOffset -(cellHeight / 6.0)) )
		{
			idx++;
			*outDropHighlight = PXListViewDropAbove;
			PXLog( @"*** ABOVE %ld (below %d)", idx, idx -1 );
		}
		else
			PXLog( @"*** ON %ld", idx );
		
		if( idx > _numberOfRows )
			idx = NSUIntegerMax;
		
		return idx;
	}
	else
	{
		PXLog( @"*** ON %d", NSUIntegerMax );
		return NSUIntegerMax;
	}
}


-(PXListViewCell*)	cellForDropHighlight: (PXListViewDropHighlight*)dhl row: (NSUInteger*)idx
{
	PXListViewCell*		newCell = nil;
	if( (*idx) >= _numberOfRows && _numberOfRows > 0 )
	{
		*dhl = PXListViewDropBelow;
		*idx = _numberOfRows -1;
		newCell = [self visibleCellForRow: _numberOfRows -1];
	}
	else
	{
		newCell = ((*idx) >= _numberOfRows) ? nil : [self visibleCellForRow: *idx];
	}
	
	return newCell;
}


- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	PXLog( @"draggingEntered" );
	
	NSDragOperation	theOperation = NSDragOperationNone;
	
	NSUInteger				oldDropRow = _dropRow;
	PXListViewDropHighlight	oldDropHighlight = _dropHighlight;

	if( [_delegate respondsToSelector: @selector(listView:validateDrop:proposedRow:proposedDropHighlight:)] )
	{
		NSPoint		dragMouse = [[self documentView] convertPoint: [sender draggingLocation] fromView: nil];
		PXLog( @"dragMouse = %@", NSStringFromPoint(dragMouse) );
		_dropRow = [self indexOfRowAtPoint: dragMouse returningProposedDropHighlight: &_dropHighlight];
		
		theOperation = [_delegate listView: self validateDrop: sender proposedRow: _dropRow
														proposedDropHighlight: _dropHighlight];
	}

	PXLog( @"op = %lu, row = %ld, hl = %lu", theOperation, _dropRow, _dropHighlight );
	
	if( theOperation != NSDragOperationNone )
	{
		if( oldDropRow != _dropRow
			|| oldDropHighlight != _dropHighlight )
		{
			PXListViewCell*	newCell = [self cellForDropHighlight: &_dropHighlight row: &_dropRow];
			PXListViewCell*	oldCell = [self cellForDropHighlight: &oldDropHighlight row: &oldDropRow];
			
			[oldCell setDropHighlight: PXListViewDropNowhere];
			[newCell setDropHighlight: _dropHighlight];
			PXListViewDropHighlight	dropHL = ((_dropRow == _numberOfRows) ? PXListViewDropAbove : PXListViewDropOn);
			PXLog( @"TOTAL DROP %s", dropHL == PXListViewDropOn ? "on" : "above" );
			[[self documentView] setDropHighlight: dropHL];
		}
		else
			PXLog(@"TOTAL DROP unchanged");
	}
	else
		PXLog( @"TOTAL DROP NOWHERE" );
	
	return theOperation;
}


- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender /* if the destination responded to draggingEntered: but not to draggingUpdated: the return value from draggingEntered: is used */
{
	PXLog( @"draggingUpdated" );
	
	NSDragOperation	theOperation = NSDragOperationNone;
	
	NSUInteger				oldDropRow = _dropRow;
	PXListViewDropHighlight	oldDropHighlight = _dropHighlight;

	if( [_delegate respondsToSelector: @selector(listView:validateDrop:proposedRow:proposedDropHighlight:)] )
	{
		NSPoint		dragMouse = [[self documentView] convertPoint: [sender draggingLocation] fromView: nil];
		PXLog( @"dragMouse = %@", NSStringFromPoint(dragMouse) );
		_dropRow = [self indexOfRowAtPoint: dragMouse returningProposedDropHighlight: &_dropHighlight];
		
		theOperation = [_delegate listView: self validateDrop: sender proposedRow: _dropRow
														proposedDropHighlight: _dropHighlight];
	}
	
	NSLog( @"op = %lu, row = %ld, hl = %lu", theOperation, _dropRow, _dropHighlight );
	
	if( theOperation != NSDragOperationNone )
	{
		if( oldDropRow != _dropRow
			|| oldDropHighlight != _dropHighlight )
		{
			PXListViewCell*	newCell = [self cellForDropHighlight: &_dropHighlight row: &_dropRow];
			PXListViewCell*	oldCell = [self cellForDropHighlight: &oldDropHighlight row: &oldDropRow];
			
			[oldCell setDropHighlight: PXListViewDropNowhere];
			[newCell setDropHighlight: _dropHighlight];
			PXListViewDropHighlight	dropHL = ((_dropRow == _numberOfRows) ? PXListViewDropAbove : PXListViewDropOn);
			NSLog( @"TOTAL DROP %s", dropHL == PXListViewDropOn ? "on" : "above" );
			[[self documentView] setDropHighlight: dropHL];
		}
		else
			PXLog(@"TOTAL DROP unchanged");
	}
	else
	{
		PXLog( @"TOTAL DROP NOWHERE" );
		[self setShowsDropHighlight: NO];
	}
	
	return theOperation;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
#pragma unused(sender)
	PXListViewCell*	oldCell = _dropRow == NSUIntegerMax ? nil : [self visibleCellForRow: _dropRow];
	[oldCell setDropHighlight: PXListViewDropNowhere];
	
	[self setShowsDropHighlight: NO];
	
	_dropRow = 0;
	_dropHighlight = PXListViewDropNowhere;
}


//- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
//{
//	
//}
//
//
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	if( ![[self delegate] respondsToSelector: @selector(listView:acceptDrop:row:dropHighlight:)] )
		return NO;
	
	BOOL	accepted = [[self delegate] listView: self acceptDrop: sender row: _dropRow dropHighlight: _dropHighlight];
	
	_dropRow = 0;
	_dropHighlight = PXListViewDropNowhere;
	
	return accepted;
}


- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
#pragma unused(sender)	
}


- (void)draggingEnded:(id <NSDraggingInfo>)sender
{
#pragma unused(sender)
	PXListViewCell*	oldCell = _dropRow == NSUIntegerMax ? nil : [self visibleCellForRow: _dropRow];
	[oldCell setDropHighlight: PXListViewDropNowhere];
	
	[self setShowsDropHighlight: NO];
}


- (BOOL)wantsPeriodicDraggingUpdates
{
	return YES;
}


-(void)	setDropRow: (NSUInteger)row dropHighlight: (PXListViewDropHighlight)dropHighlight
{
	_dropRow = row;
	_dropHighlight = dropHighlight;
	
	[self setNeedsDisplay: YES];
}

#pragma mark -
#pragma mark Sizing

- (void)viewWillStartLiveResize
{
	_inLiveResize = YES;
}

- (void)viewDidEndLiveResize
{
	[super viewDidEndLiveResize];
	
	//Change the layout of the cells
	[_visibleCells removeAllObjects];
	[[self documentView] setSubviews:[NSArray array]];
	
	[self cacheCellLayout];
	[self addCellsFromVisibleRange];
	
	_currentRange = [self visibleRange];
	
	_inLiveResize = NO;
}

#pragma mark -
#pragma mark Accessibility

-(NSArray*)	accessibilityAttributeNames
{
	NSMutableArray*	attribs = [[[super accessibilityAttributeNames] mutableCopy] autorelease];
	
	[attribs addObject: NSAccessibilityRoleAttribute];
	[attribs addObject: NSAccessibilityVisibleChildrenAttribute];
	[attribs addObject: NSAccessibilitySelectedChildrenAttribute];
	[attribs addObject: NSAccessibilityOrientationAttribute];
	[attribs addObject: NSAccessibilityEnabledAttribute];
	
	return attribs;
}

- (BOOL)accessibilityIsAttributeSettable:(NSString *)attribute
{
	if( [attribute isEqualToString: NSAccessibilityRoleAttribute]
		or [attribute isEqualToString: NSAccessibilityVisibleChildrenAttribute]
		or [attribute isEqualToString: NSAccessibilitySelectedChildrenAttribute]
		or [attribute isEqualToString: NSAccessibilityContentsAttribute]
		or [attribute isEqualToString: NSAccessibilityOrientationAttribute]
		or [attribute isEqualToString: NSAccessibilityChildrenAttribute]
		or [attribute isEqualToString: NSAccessibilityEnabledAttribute] )
	{
		return NO;
	}
	else
		return [super accessibilityIsAttributeSettable: attribute];
}


-(id)	accessibilityAttributeValue: (NSString *)attribute
{
	if( [attribute isEqualToString: NSAccessibilityRoleAttribute] )
	{
		return NSAccessibilityListRole;
	}
	else if( [attribute isEqualToString: NSAccessibilityVisibleChildrenAttribute]
				|| [attribute isEqualToString: NSAccessibilityContentsAttribute]
				|| [attribute isEqualToString: NSAccessibilityChildrenAttribute] )
	{
		return _visibleCells;
	}
	else if( [attribute isEqualToString: NSAccessibilitySelectedChildrenAttribute] )
	{
		return [self visibleCellsForRowIndexes: _selectedRows];
	}
	else if( [attribute isEqualToString: NSAccessibilityOrientationAttribute] )
	{
		return NSAccessibilityVerticalOrientationValue;
	}
	else if( [attribute isEqualToString: NSAccessibilityEnabledAttribute] )
	{
		return [NSNumber numberWithBool: YES];
	}
	else
		return [super accessibilityAttributeValue: attribute];
}


-(BOOL)	accessibilityIsIgnored
{
	return NO;
}

@end
