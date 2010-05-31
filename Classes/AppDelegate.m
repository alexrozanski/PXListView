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
	
	[_listItems addObject:@"Hello1"];
	[_listItems addObject:@"Hello2"];
	[_listItems addObject:@"Hello3"];
	[_listItems addObject:@"Hello4"];
	[_listItems addObject:@"Hello5"];
	[_listItems addObject:@"Hello6"];
	[_listItems addObject:@"Hello7"];
	[_listItems addObject:@"Hello8"];
	[_listItems addObject:@"Hello9"];
	
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
