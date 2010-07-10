//
//  PXListDocumentView.h
//  PXListView
//
//  Created by Alex Rozanski on 29/05/2010.
//  Copyright 2010 Alex Rozanski. http://perspx.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PXListView;

@interface PXListDocumentView : NSView
{
	PXListView	*_listView;
	BOOL		_showsDropHighlight;
}

@property (assign) PXListView	*listView;
@property (assign) BOOL			showsDropHighlight;

@end
