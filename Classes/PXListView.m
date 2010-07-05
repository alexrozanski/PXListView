//
//  PXListView.m
//  PXListView
//
//  Created by Alex Rozanski on 29/05/2010.
//  Copyright 2010 Alex Rozanski. http://perspx.com. All rights reserved.
//

#import "PXListView.h"
#import "PXListView+Private.h"

#import "PXListViewCell.h"
#import "PXListViewCell+Private.h"


@implementation PXListView

@synthesize delegate = _delegate;
@synthesize cellSpacing = _cellSpacing;
@synthesize selectedRow = _selectedRow;

#pragma mark -
#pragma mark Init/Dealloc

- (id)initWithCoder:(NSCoder*)decoder
{
	if(self = [super initWithCoder:decoder]) {
		_reusableCells = [[NSMutableArray alloc] init];
		_visibleCells = [[NSMutableArray alloc] init];
	}
	
	return self;
}

- (void)awakeFromNib
{
	//Subscribe to scrolling notification
	NSClipView *contentView = [self contentView];
	[contentView setPostsBoundsChangedNotifications:YES];
	
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(contentViewBoundsDidChange:)
												 name:NSViewBoundsDidChangeNotification
											   object:contentView];
	
	//Tag ourselves onto the document view
	[[self documentView] setListView:self];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[_reusableCells release];
	[_visibleCells release];
	[super dealloc];
}

#pragma mark -
#pragma mark Data Handling

- (void)reloadData
{
	id <PXListViewDelegate> delegate = [self delegate];
	
	//Clean up cached resources
	[_reusableCells removeAllObjects];
	[_visibleCells removeAllObjects];
	free(_cellYOffsets);
	
	_selectedRow = -1;
	
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

- (void)setSelectedRow:(NSInteger)row
{
	NSInteger oldSelectedRow = _selectedRow;
	
	if(oldSelectedRow>=_currentRange.location&&oldSelectedRow<=NSMaxRange(_currentRange)) {
		PXListViewCell *oldSelectedCell = [self visibleCellForRow:oldSelectedRow];
		[oldSelectedCell setNeedsDisplay:YES];
	}
	
	PXListViewCell *newSelectedCell = [self visibleCellForRow:row];
	[newSelectedCell setNeedsDisplay:YES];
	
	_selectedRow = row;
}

- (void)deselectRows
{
	NSInteger oldSelectedRow = _selectedRow ;
	_selectedRow = -1;
	
	PXListViewCell *oldSelectedCell = [self visibleCellForRow:oldSelectedRow];
	[oldSelectedCell setNeedsDisplay:YES];
}

#pragma mark -
#pragma mark Cell Handling

- (void)enqueueCell:(PXListViewCell*)cell
{
	[_reusableCells addObject:cell];
	[_visibleCells removeObject:cell];
	[cell removeFromSuperview];
}

- (PXListViewCell*)dequeueCellWithReusableIdentifier:(NSString*)identifier
{
	if([_reusableCells count]==0) {
		return nil;
	}
	
	//Search backwards looking for a match since removing from end of array is generally quicker
	for(NSUInteger i = [_reusableCells count]-1; i>=0;i--)
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
	NSInteger startRow = -1;
	NSInteger endRow = -1;
	
	BOOL inRange = NO;
	for(NSInteger i=0;i<_numberOfRows;i++) {
		if(NSIntersectsRect([self rectOfRow:i], visibleRect)) {
			if(startRow==-1) {
				startRow = i;
				inRange = YES;
			}
		}
		else {
			if(inRange) {
				endRow = i;
				break;
			}
		}
	}
	
	if(endRow==-1) {
		endRow = _numberOfRows; 
	}
	
	return NSMakeRange(startRow, endRow-startRow);
}

- (PXListViewCell*)visibleCellForRow:(NSInteger)row
{
	PXListViewCell *theCell = nil;
	
	for(id cell in _visibleCells) {
		if([cell row]==row) {
			theCell = cell;
			break;
		}
	}
	
	return theCell;
}

- (void)addCellsFromVisibleRange
{
	id <PXListViewDelegate> delegate = [self delegate];
	
	if([delegate conformsToProtocol:@protocol(PXListViewDelegate)])
	{
		NSRange visibleRange = [self visibleRange];
		
		for(NSInteger i=visibleRange.location;i<NSMaxRange(visibleRange);i++) {
			id cell = [delegate listView:self cellForRow:i];
			[_visibleCells addObject:cell];
			[self addNewVisibleCell:cell atRow:i];
		}
	}
}

- (void)updateCells
{	
	if(_inLiveResize) {
		return;
	}
	
	NSRange visibleRange = [self visibleRange];
	NSRange intersectionRange = NSIntersectionRange(visibleRange, _currentRange);
	
	if(visibleRange.location==_currentRange.location&&
	   NSMaxRange(visibleRange)==NSMaxRange(_currentRange)) {
		return;
	}
	
	if(intersectionRange.location==0&&intersectionRange.length==0) {
		//We'll have to rebuild all the cells
		[_reusableCells addObjectsFromArray:_visibleCells];
		[_visibleCells removeAllObjects];
		[[self documentView] setSubviews:[NSArray array]];
		[self addCellsFromVisibleRange];
	}
	else {
		if(visibleRange.location<_currentRange.location) { //Add top 
			for(NSInteger i=_currentRange.location;i>visibleRange.location;i--)
			{
				NSInteger newRow = i-1;
				PXListViewCell *cell = [[self delegate] listView:self cellForRow:newRow];
				[_visibleCells insertObject:cell atIndex:0];
				[self addNewVisibleCell:cell atRow:newRow];
			}
		}
		else if(visibleRange.location>_currentRange.location) { //Remove top
			for(NSInteger i=visibleRange.location;i>_currentRange.location;i--) {
				PXListViewCell *firstCell = [_visibleCells objectAtIndex:0];
				[self enqueueCell:firstCell];
			}
		}
		
		if(NSMaxRange(visibleRange)>NSMaxRange(_currentRange)) { //Add bottom
			for(NSInteger i=NSMaxRange(_currentRange);i<NSMaxRange(visibleRange);i++)
			{
				NSInteger newRow = i;
				PXListViewCell *cell = [[self delegate] listView:self cellForRow:newRow];
				[_visibleCells addObject:cell];
				[self addNewVisibleCell:cell atRow:newRow];
			}
		}
		else if(NSMaxRange(visibleRange)<NSMaxRange(_currentRange)) { //Remove bottom
			for(NSInteger i=NSMaxRange(_currentRange);i>NSMaxRange(visibleRange);i--) {
				PXListViewCell *lastCell = [_visibleCells lastObject];
				[self enqueueCell:lastCell];
			}
		}
	}
	
	NSLog(@"No of cells in view hierarchy: %d", [_visibleCells count]);
	
	_currentRange = visibleRange;
}

- (void)addNewVisibleCell:(PXListViewCell*)cell atRow:(NSInteger)row
{
	[[self documentView] addSubview:cell];
	[cell setListView:self];
	[cell setRow:row];
	[self layoutCell:cell];
}

#pragma mark -
#pragma mark Layout

- (NSRect)contentViewRect
{
	NSRect frame = [self frame];
	NSSize frameSize = NSMakeSize(NSWidth(frame), NSHeight(frame));
	BOOL hasVertScroller = NSHeight(frame)<_totalHeight;
	NSSize availableSize = [[self class] contentSizeForFrameSize:frameSize
										   hasHorizontalScroller:NO
											 hasVerticalScroller:hasVertScroller
													  borderType:[self borderType]];
	
	return NSMakeRect(0, 0, availableSize.width, availableSize.height);
}

- (NSRect)rectOfRow:(NSInteger)row
{
	id <PXListViewDelegate> delegate = [self delegate];
	
	if([delegate conformsToProtocol:@protocol(PXListViewDelegate)])
	{
		NSRect contentViewRect = [self contentViewRect];
		CGFloat rowHeight = [delegate listView:self heightOfRow:row];
		
		return NSMakeRect(0, _cellYOffsets[row], NSWidth(contentViewRect), rowHeight);
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
		
		for(NSInteger i=0;i<_numberOfRows;i++) {
			_cellYOffsets[i] = totalHeight;
			CGFloat cellHeight = [delegate listView:self heightOfRow:i];
			
			totalHeight+=cellHeight+[self cellSpacing];
		}
		
		_totalHeight = totalHeight;
		
		NSRect bounds = [self bounds];
		CGFloat documentHeight = _totalHeight>NSHeight(bounds)?_totalHeight:NSHeight(bounds);
		
		[[self documentView] setFrame:NSMakeRect(0, 0, NSWidth([self bounds]), documentHeight)];
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
	CGFloat documentHeight = _totalHeight>NSHeight(bounds)?_totalHeight:NSHeight(bounds);
	
	//Set the new height of the document view
	[[self documentView] setFrame:NSMakeRect(0, 0, NSWidth([self contentViewRect]), documentHeight)];
}

- (void)layoutCell:(PXListViewCell*)cell
{
	NSInteger row = [cell row];
	[cell setFrame:[self rectOfRow:row]];
}

#pragma mark -
#pragma mark Scrolling

- (void)contentViewBoundsDidChange:(NSNotification *)notification
{
	[self updateCells];
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

@end
