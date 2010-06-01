//
//  PXListViewCell.h
//  PXListView
//
//  Created by Alex Rozanski on 29/05/2010.
//  Copyright 2010 Alex Rozanski. http://perspx.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PXListView;

@interface PXListViewCell : NSView {
	NSString *_reusableIdentifier;
	
	PXListView *_listView;
	NSInteger _row;
}

@property (assign) PXListView *listView;
@property (readonly) NSString *reusableIdentifier;
@property (readonly) NSInteger row;
@property (readonly,getter=isSelected) BOOL selected;

- (id)initWithReusableIdentifier:(NSString*)identifier;
- (void)prepareForReuse;

@end
