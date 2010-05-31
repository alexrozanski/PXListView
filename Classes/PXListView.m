//
//  PXListView.m
//  PXListView
//
//  Created by Alex Rozanski on 29/05/2010.
//  Copyright 2010 Alex Rozanski. http://perspx.com. All rights reserved.
//

#import "PXListView.h"

#import "PXListViewCell.h"
#import "PXListViewCell+Private.h"

@interface PXListView ()
- (void)cacheCellLayout;
- (void)layoutCells;
- (NSRect)viewportRect;
- (void)layoutCell:(PXListViewCell*)cell;
- (void)addNewVisibleCell:(PXListViewCell*)cell atRow:(NSInteger)row;
@end


@implementation PXListView

@synthesize delegate = _delegate;
@synthesize cellSpacing = _cellSpacing;

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
	NSClipView *contentView = [self contentView];
	[contentView setPostsBoundsChangedNotifications:YES];
	
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(contentViewBoundsDidChange:)
												 name:NSViewBoundsDidChangeNotification
											   object:contentView];
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
	
	if([delegate conformsToProtocol:@protocol(PXListViewDelegate)])
	{
		_numberOfRows = [delegate numberOfRowsInListView:self];
		
		[self cacheCellLayout];
		
		NSRect viewportRect = [self viewportRect];
		for(NSInteger i=0;i<_numberOfRows;i++) {
			if(NSIntersectsRect([self rectOfRow:i], viewportRect)) {
				id cell = [[self delegate] listView:self cellForRow:i];
				[[self documentView] addSubview:cell];
				[cell setRow:i];
				[_visibleCells addObject:cell];
			}
		}
		
		[self layoutCells];
	}
}

#pragma mark -
#pragma mark Cell Handling

- (PXListViewCell*)dequeueCellWithReusableIdentifier:(NSString*)identifier
{
	PXListViewCell *dequeuedCell = nil;
	
	for(id cell in _reusableCells) {
		if([[cell reusableIdentifier] isEqual:identifier]) {
			dequeuedCell = cell;
			break;
		}
	}
	
	[dequeuedCell retain];
	[_reusableCells removeObject:dequeuedCell];
	
	return [dequeuedCell autorelease];
}

- (PXListViewCell*)visibleCellForRow:(NSInteger)row
{
	for(id cell in _visibleCells) {
		if([cell row]==row) {
			return cell;
		}
	}
	
	return nil;
}

- (void)updateCells:(NSEvent*)event
{
	BOOL scrollUp = YES;
	
	if([event deltaY]<0) {
		scrollUp = NO;
	}
	
	NSRect visibleRect = [self documentVisibleRect];
	
	if(!scrollUp) 
	{
		id firstCell = [_visibleCells objectAtIndex:0];
		NSRect cellFrame = [self rectOfRow:[firstCell row]];
		
		if(!NSIntersectsRect(cellFrame, visibleRect)) {
			[_reusableCells addObject:firstCell];
			[_visibleCells removeObject:firstCell];
			[firstCell removeFromSuperview];
		}
		
		NSInteger newRow = [[_visibleCells lastObject] row]+1;
		
		if(newRow<=_numberOfRows) {
			NSRect newCellFrame = [self rectOfRow:newRow];
			
			if(NSIntersectsRect(newCellFrame, visibleRect)) {
				PXListViewCell *newCell = [[self delegate] listView:self cellForRow:newRow];
				[_visibleCells addObject:newCell];
				[self addNewVisibleCell:newCell atRow:newRow];
			}
		}
	}
	else {
		id lastCell = [_visibleCells lastObject];
		NSRect cellFrame = [self rectOfRow:[lastCell row]];
		
		if(!NSIntersectsRect(cellFrame, visibleRect)) {
			[_reusableCells addObject:lastCell];
			[_visibleCells removeObject:lastCell];
			[lastCell removeFromSuperview];
		}
		
		NSInteger newRow = [[_visibleCells objectAtIndex:0] row]-1;
		
		if(newRow>=0) {
			NSRect newCellFrame = [self rectOfRow:newRow];
			
			if(NSIntersectsRect(newCellFrame, visibleRect)) {
				PXListViewCell *newCell = [[self delegate] listView:self cellForRow:newRow];
				[_visibleCells insertObject:newCell atIndex:0];
				[self addNewVisibleCell:newCell atRow:newRow];
			}
		}
	}
}

- (void)addNewVisibleCell:(PXListViewCell*)cell atRow:(NSInteger)row
{
	[[self documentView] addSubview:cell];
	[cell setRow:row];
	[self layoutCell:cell];
}

#pragma mark -
#pragma mark Layout

- (NSRect)rectOfRow:(NSInteger)row
{
	if([[self delegate] conformsToProtocol:@protocol(PXListViewDelegate)]) {
		NSRect bounds = [self bounds];
		
		return NSMakeRect(0, _cellYOffsets[row], NSWidth(bounds), [[self delegate] listView:self heightOfRow:row]);
	}
	
	return NSZeroRect;
}

- (void)cacheCellLayout
{
	CGFloat totalHeight = 0;
	
	//Allocate the offset caching array
	_cellYOffsets = (CGFloat*)malloc(sizeof(CGFloat)*_numberOfRows);
	
	for(NSInteger i=0;i<_numberOfRows;i++) {
		_cellYOffsets[i] = totalHeight;
		CGFloat cellHeight = [[self delegate] listView:self heightOfRow:i];
		
		totalHeight+=cellHeight+[self cellSpacing];
	}
	
	_totalHeight = totalHeight;
	
	[[self documentView] setFrame:NSMakeRect(0, 0, NSWidth([self bounds]), _totalHeight)];
}

- (NSRect)viewportRect
{
	NSRect frame = [self frame];
	NSSize frameSize = NSMakeSize(NSWidth(frame), NSHeight(frame));
	BOOL hasVertScroller = NSHeight(frame)<_totalHeight;
	
	NSSize availableSize = [NSScrollView contentSizeForFrameSize:frameSize
										   hasHorizontalScroller:NO
											 hasVerticalScroller:hasVertScroller
													  borderType:[self borderType]];
	
	return NSMakeRect(0, 0, availableSize.width, availableSize.height);
}

- (void)layoutCells
{
	NSRect availableRect = [self viewportRect];
	
	//Set the frames of the cells
	for(id cell in _visibleCells) {
		NSInteger row = [cell row];
		CGFloat cellHeight = [[self delegate] listView:self heightOfRow:row];
		NSRect cellFrame = NSMakeRect(0, _cellYOffsets[row], NSWidth(availableRect), cellHeight);	
		[cell setFrame:cellFrame];
	}
}

- (void)layoutCell:(PXListViewCell*)cell
{
	NSRect availableRect = [self viewportRect];	
	
	NSInteger row = [cell row];
	CGFloat cellHeight = [[self delegate] listView:self heightOfRow:row];
	NSRect cellFrame = NSMakeRect(0, _cellYOffsets[row], NSWidth(availableRect), cellHeight);	
	[cell setFrame:cellFrame];
}

#pragma mark -
#pragma mark Sizing

- (void)viewDidEndLiveResize
{
	[super viewDidEndLiveResize];
	
	//Change the layout of the cells
	[_visibleCells removeAllObjects];
	[[self documentView] setSubviews:[NSArray array]];
	NSRect viewportRect = [self viewportRect];

	[self cacheCellLayout];
	
	for(NSInteger i=0;i<_numberOfRows;i++) {
		if(NSIntersectsRect([self rectOfRow:i], viewportRect)) {
			id cell = [[self delegate] listView:self cellForRow:i];
			[[self documentView] addSubview:cell];
			[cell setRow:i];
			[_visibleCells addObject:cell];
		}
	}
	
	[self layoutCells];
}

#pragma mark -
#pragma mark Scrolling

- (void)scrollWheel:(NSEvent *)theEvent
{
	[super scrollWheel:theEvent];
	[self updateCells:theEvent];
}

- (void)contentViewBoundsDidChange:(NSNotification *)notification
{
}

@end
