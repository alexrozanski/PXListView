//
//  AppDelegate.m
//  PXListView
//
//  Created by Alex Rozanski on 29/05/2010.
//  Copyright 2010 Alex Rozanski. http://perspx.com. All rights reserved.
//

#import "AppDelegate.h"

#import "MyListViewCell.h"

@implementation AppDelegate

#pragma mark -
#pragma mark Init/Dealloc

- (void)awakeFromNib
{
	[listView setCellSpacing:2];
	
	_listItems = [[NSMutableArray alloc] init];

	for(NSInteger i=0;i<1000;i++) {
		NSString *title = [[NSString alloc] initWithFormat:@"Item%d", i+1];
		[_listItems addObject:title];
		[title release];
	}
	
	[listView reloadData];
}

- (void)dealloc
{
	[_listItems release];
	[super dealloc];
}

#pragma mark -
#pragma mark List View Delegate Methods

- (NSInteger)numberOfRowsInListView:(PXListView*)aListView
{
	return [_listItems count];
}

- (PXListViewCell*)listView:(PXListView*)aListView cellForRow:(NSInteger)row
{
	MyListViewCell *cell = (MyListViewCell*)[aListView dequeueCellWithReusableIdentifier:@"MyListViewCell"];
	
	if(!cell) {
		cell = [[MyListViewCell alloc] initWithReusableIdentifier:@"MyListViewCell"];
	}
	
	[cell setTitle:[_listItems objectAtIndex:row]];
	
	return cell;
}

- (NSInteger)listView:(PXListView*)aListView heightOfRow:(NSInteger)row
{
	return 50;
}

@end
