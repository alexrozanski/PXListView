PXListView
==========

An optimized list view control for Mac OS X 10.5 and greater. It was created after I wrote [this post][1] on the subject.

PXListView is licensed under the New BSD license.

`PXListView` uses similar optimizations as `UITableView` for the iPhone, by enqueuing and dequeuing `NSView`s which are used to display rows, in order to keep a low memory footprint when there are a large number of rows in the list, yet still allowing each row to be represented  by an `NSView`, which is easier than dealing with cells.

The architecture of the control is based on the list view controls which are present in both [Tweetie][2] (Mac) and [Echofon][3] (Mac).

The project is still very much a work in progress, and as such no documentation exists at current.

How the control works
---------------------

Each row in the list view is displayed using an instance of `PXListViewCell` (which is a subclass of `NSView`). The delegate of `PXListView` responds to three messages in order for the control to function:

1. `numberOfCellsInListView:`
2. `-listView:cellForRow:`
3. `-listView:heightOfRow:`

###Optimizations###
`PXListView` only keeps the bare minimum of list view cells in the view hierarchy to be performant, and when rows are scrolled onscreen new cells are added to the view hierarchy to display the rows, and when the rows are scrolled offscreen the associated cells are removed from the view hierarchy.

###Returning cells###
When responding to `-listView:cellForRow:`, the delegate should first call `-dequeueCellWithReusableIdentifier:` on the list view, passing in the reusable cell identifier, to see if there are any reusable cells available. If this returns `nil` then a new cell can be created using the initializer `initWithReusableIdentifier:` (declared on PXListViewCell). this keeps the memory footprint of the control as low as possible by reusing cells that have been scrolled offscreen, removed from the view hierarchy and cached.

###Using PXListViewCell###
`PXListViewCell` is an abstract superclass, implementing the bare minimum for such features as cell selection and declaring methods relied on by the list view.

You should create a concrete subclass of `PXListViewCell` when using it in the list view, where `drawRect:` can be overridden to do custom drawing, and properties used to store data for the cell can be declared on this subclass. The example project (as part of the repository) shows this.

Attributions
-----------

Thanks to [Mike Abdullah][4] for optimizations related to cell dequeuing.


  [1]: http://perspx.com/blog/archives/1427/making-list-views-really-fast/
  [2]: http://www.atebits.com/tweetie-mac/
  [3]: http://www.echofon.com/twitter/mac/
  [4]: http://mikeabdullah.net/