//
//  PXListView.h
//  PXListView
//
//  Created by Alex Rozanski on 29/05/2010.
//  Copyright 2010 Alex Rozanski. http://perspx.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "PXListViewDelegate.h"
#import "PXListViewCell.h"

#ifndef PXLog
#define	PXLog(...)		
#endif


@interface PXListView : NSScrollView
{
	id <PXListViewDelegate> _delegate;
	
	NSMutableArray *_reusableCells;
	NSMutableArray *_visibleCells;
	NSRange _currentRange;
	
	NSUInteger _numberOfRows;
	NSMutableIndexSet *_selectedRows;
	
	NSRange	_visibleRange;
	CGFloat	_totalHeight;
	CGFloat	*_cellYOffsets;
	
	CGFloat	_cellSpacing;
	
	BOOL _inLiveResize;
	BOOL _allowsEmptySelection;
	BOOL _allowsMultipleSelection;
	BOOL _verticalMotionCanBeginDrag;
	
	NSUInteger _dropRow;
	PXListViewDropHighlight	_dropHighlight;
}

@property (readwrite, assign) IBOutlet id <PXListViewDelegate>	delegate;
@property (readwrite, assign) CGFloat cellSpacing;
@property (readwrite, retain) NSIndexSet* selectedRows;
@property (readwrite, assign) NSUInteger selectedRow;	// shorthand for selectedRows.
@property (readwrite, assign) BOOL allowsEmptySelection;
@property (readwrite, assign) BOOL allowsMultipleSelection;
@property (readwrite, assign) BOOL verticalMotionCanBeginDrag;

- (void)reloadData;

- (PXListViewCell*)dequeueCellWithReusableIdentifier:(NSString*)identifier;

- (NSRange)visibleRange;
- (NSRect)rectOfRow:(NSUInteger)row;
- (void)deselectRows;
- (void)selectRowIndexes:(NSIndexSet*)rows byExtendingSelection:(BOOL)doExtend;

- (void)scrollRowToVisible:(NSUInteger)row;

-(NSImage*)dragImageForRowsWithIndexes:(NSIndexSet*)dragRows
								 event:(NSEvent*)dragEvent
						   clickedCell:(PXListViewCell*)clickedCell
								offset:(NSPointPointer)dragImageOffset;
- (void)setShowsDropHighlight:(BOOL)inState;
- (void)setDropRow:(NSUInteger)row dropHighlight:(PXListViewDropHighlight)dropHighlight;

@end
