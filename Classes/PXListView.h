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
	
	NSInteger _numberOfRows;
	NSInteger _selectedRow;
}

@property (readwrite, assign) id <PXListViewDelegate> delegate;

- (void)reloadData;

- (PXListViewCell*)dequeueCellWithReusableIdentifier:(NSString*)identifier;

@end
