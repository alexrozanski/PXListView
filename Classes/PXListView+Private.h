//
//  PXListView+Private.h
//  PXListView
//
//  Created by Alex Rozanski on 01/06/2010.
//  Copyright 2010 Alex Rozanski. http://perspx.com. All rights reserved.
//

@interface PXListView ()

- (NSRect)			contentViewRect;

- (void)			cacheCellLayout;
- (void)			layoutCells;
- (void)			layoutCell: (PXListViewCell*)cell;

- (void)			addCellsFromVisibleRange;
- (void)			addNewVisibleCell: (PXListViewCell*)cell atRow: (NSInteger)row;
- (PXListViewCell*)	visibleCellForRow: (NSInteger)row;
- (NSArray*)		visibleCellsForRowIndexes: (NSIndexSet*)rows;

- (void)			updateCells;

- (void)			enqueueCell: (PXListViewCell*)cell;

- (void)			handleMouseDown: (NSEvent*)theEvent	inCell: (PXListViewCell*)theCell;
- (void)			handleMouseDownOutsideCells: (NSEvent*)theEvent;

@end