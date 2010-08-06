//
//  PXListViewCell.h
//  PXListView
//
//  Created by Alex Rozanski on 29/05/2010.
//  Copyright 2010 Alex Rozanski. http://perspx.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PXListViewDropHighlight.h"


@class PXListView;



@interface PXListViewCell : NSView
{
	NSString				*_reusableIdentifier;
	
	PXListView				*_listView;
	NSUInteger				_row;
	PXListViewDropHighlight	_dropHighlight;
}

@property (assign) PXListView				*listView;
@property (readonly) NSString				*reusableIdentifier;
@property (readonly) NSUInteger				row;
@property (readonly,getter=isSelected) BOOL	selected;
@property (assign) PXListViewDropHighlight	dropHighlight;

- (id)		initWithReusableIdentifier: (NSString*)identifier;
- (void)	prepareForReuse;

@end
