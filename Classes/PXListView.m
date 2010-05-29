//
//  PXListView.m
//  PXListView
//
//  Created by Alex Rozanski on 29/05/2010.
//  Copyright 2010 Alex Rozanski. http://perspx.com. All rights reserved.
//

#import "PXListView.h"

#import "PXListViewCell.h"


@implementation PXListView

@synthesize delegate = _delegate;

#pragma mark -
#pragma mark Init/Dealloc

- (id)initWithFrame:(NSRect)frameRect
{
	if(self = [super initWithFrame:frameRect]) {
		_reusableCells = [[NSMutableArray alloc] init];
	}
	
	return self;
}

- (void)dealloc
{
	[_reusableCells release];
	[super dealloc];
}

#pragma mark -
#pragma mark Data Handling

- (void)reloadData
{
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
	
	return dequeuedCell;
}

@end
