PXListView
==========

An optimized list view control for Mac OS X 10.5 and greater. It was created after I wrote [this post][1] on the subject.

PXListView uses similar optimizations as UITableView for the iPhone, by enqueuing and dequeuing NSViews which are used to display rows, in order to keep a low memory footprint when there are a large number of rows in the list, yet still allowing each row to be represented  by an NSView, which is easier than dealing with cells.

The project is still very much a work in progress, and as such no documentation exists at current.


  [1]: http://perspx.com/blog/archives/1427/making-list-views-really-fast/