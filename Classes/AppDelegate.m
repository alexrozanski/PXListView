//
//  AppDelegate.m
//  PXListView
//
//  Created by Alex Rozanski on 29/05/2010.
//  Copyright 2010 Alex Rozanski. http://perspx.com. All rights reserved.
//

#import "AppDelegate.h"

#import "MyListViewCell.h"


#pragma mark Constants

#define LISTVIEW_CELL_IDENTIFIER		@"MyListViewCell"
#define NUM_EXAMPLE_ITEMS				1000


@implementation AppDelegate

#pragma mark -
#pragma mark Init/Dealloc

-(void)	awakeFromNib
{
	[listView setCellSpacing: 2];
	//[listView setAllowsEmptySelection: YES];
	//[listView setAllowsMultipleSelection: YES];
	
	_listItems = [[NSMutableArray alloc] init];

	// Create a bunch of rows as a test:
	for( NSInteger i = 0; i < NUM_EXAMPLE_ITEMS; i++ )
	{
		NSString *title = [[NSString alloc] initWithFormat: @"Item %d", i +1]; // We're in a tight loop
		[_listItems addObject: title];
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
	MyListViewCell *cell = (MyListViewCell*)[aListView dequeueCellWithReusableIdentifier:LISTVIEW_CELL_IDENTIFIER];
	
	if(!cell) {
		cell = [[[MyListViewCell alloc] initWithReusableIdentifier:LISTVIEW_CELL_IDENTIFIER] autorelease];
	}
	
	//Set up the new cell
	[cell setTitle:[_listItems objectAtIndex:row]];
	
	return cell;
}

- (CGFloat)listView:(PXListView*)aListView heightOfRow:(NSInteger)row
{
	return 50;
}

@end
