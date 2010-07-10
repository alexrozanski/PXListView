//
//  PXListViewDelegate.h
//  PXListView
//
//  Created by Alex Rozanski on 29/05/2010.
//  Copyright 2010 Alex Rozanski. http://perspx.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PXListView, PXListViewCell;

@protocol PXListViewDelegate <NSObject>

@required
- (NSUInteger)		numberOfRowsInListView: (PXListView*)aListView;
- (PXListViewCell*)	listView: (PXListView*)aListView cellForRow: (NSUInteger)row;
- (CGFloat)			listView: (PXListView*)aListView heightOfRow: (NSUInteger)row;

@optional
- (BOOL)			listView: (PXListView*)aListView writeRowsWithIndexes: (NSIndexSet *)rowIndexes toPasteboard: (NSPasteboard *)pboard;

@end
