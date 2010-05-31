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

@interface PXListView : NSScrollView {
	id <PXListViewDelegate> _delegate;
	
	NSMutableArray *_reusableCells;
	NSMutableArray *_visibleCells;
	NSRange _currentRange;
	
	NSInteger _numberOfRows;
	
	NSRange _visibleRange;
	CGFloat _totalHeight;
	CGFloat *_cellYOffsets;
	
	CGFloat _cellSpacing;
	
	BOOL _inLiveResize;
}

@property (readwrite, assign) IBOutlet id <PXListViewDelegate> delegate;
@property CGFloat cellSpacing;

- (void)reloadData;
- (NSRect)rectOfRow:(NSInteger)row;
- (NSRange)visibleRange;
- (PXListViewCell*)dequeueCellWithReusableIdentifier:(NSString*)identifier;

@end
