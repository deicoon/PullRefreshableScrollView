# PullRefreshableScrollView
A `NSScrollView` subclass that implements a pure pull-to-refresh logic, without any animations. It's up to you to provide the views – e.g. a loader – that are shown on the view edges, when pulled. 
It requires the delegate pattern to request these "accessory" views, and to notify you of the pull-to-refresh action.

## Getting Started

Drag `PullRefreshableScrollView.xcodeproj` into your XCode project and add its product framework as a dependency of your app's target. Then : 
* `import PullRefreshableScrollView` in your Swift files 
  * *no ObjC bridging right now, and neither planned*
* set your Scroll View's class name to `PullRefreshableScrollView` in Interface Builder 
  * *these usually enclose a table or collection view*
* write a delegate that conforms to the `PullRefreshableScrollViewDelegate` protocol 
  * *most likely this will be the dataSource and delegate of the enclosed table or collection view ; or the view controller that displays the said table or collection view*
* attach this delegate class to the `delegate` outlet of the PullRefreshableScrollView in IB
* implement the only required method in the delegate, `prScrollView(sender:, triggeredOnEdge:) -> Bool`
  * *it is called everytime the user pulls-to-refresh*
  * *it indicates the scroll view the user pulled, and the edge (currently top or bottom) on which the user pulled*
  * *it should return `false` if, for some reason (e.g. network disconnected), the refresh action could not be performed ; and `true` if the refresh action could take place – not whether it succeeded or not, only if it could be actually started*
* implement the accessors that return the accessory view – the views that are shown on the edge that was pulled by the user 
  * *e.g. `var topAccessoryView : (NSView & AccessoryViewForPullRefreshable)?` for the top edge's view*
* make your accessory views conform to AccessoryViewForPullRefreshable, which is made of various optional methods, matching change in the state of the view
  * *see source code for more details about these methods and notifications*
