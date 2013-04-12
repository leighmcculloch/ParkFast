//
//  AdvMapView.m
//  FindParking
//
//  Created by Leigh McCulloch on 24/01/13.
//  Copyright (c) 2013 Leigh McCulloch. All rights reserved.
//

#import "AdvMapView.h"
#import "AdvMapViewAnnotation.h"
#import "AdvMapViewFocusAnnotation.h"
#import "AdvMapViewSearchBar.h"
#import "MKMapRectForCoordinateRegion.h"
#import "CLPlacemark+Fields.h"
#import <QuartzCore/QuartzCore.h>

#define MIN_RELEVANT_DISTANCE_TO_FOCUS_METERS 2000

#define AUTO_ZOOM_MIN_COORD_DELTA 0.01
#define AUTO_ZOOM_MAP_INSET_TOP 100.0
#define AUTO_ZOOM_MAP_INSET_LEFT 40.0
#define AUTO_ZOOM_MAP_INSET_BOTTOM 60.0
#define AUTO_ZOOM_MAP_INSET_RIGHT 40.0

#define ANNOTATION_HIGHLIGHT_CIRCLE_RADIUS_METERS 100.0
#define ANNOTATION_HIGHLIGHT_CIRCLE_LINE_WIDTH 6.0
#define ANNOTATION_HIGHLIGHT_CIRCLE_LINE_COLOR_ALPHA 0.2
#define MAX_ZOOM_OUT 0.05

typedef enum {
	AdvMapViewUserLocationStateOff = 0,
	AdvMapViewUserLocationStateOn = 1,
	AdvMapViewUserLocationStateTracking = 2,
} AdvMapViewUserLocationState;

#define CONVERT_FROM_MKUSERTRACKINGMODE(mode) ((AdvMapViewUserLocationState)mode)
#define CONVERT_TO_MKUSERTRACKINGMODE(state) ((MKUserTrackingMode)state)

@interface AdvMapView()

@property (retain, nonatomic) IBOutlet MKMapView *mapView;
@property (retain, nonatomic) IBOutlet AdvMapViewPagingView *pagingView;
@property (retain, nonatomic) IBOutlet UIButton *userLocationToggleButton;
@property (retain, nonatomic) IBOutlet UIView *searchView;
@property (retain, nonatomic) IBOutlet UITableView *searchTableView;
@property (retain, nonatomic) IBOutlet AdvMapViewSearchBar *searchBar;
@property (assign, nonatomic) BOOL searchBarShouldBeginEditing;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *searchActivityIndicator;

@property (assign, nonatomic) AdvMapViewUserLocationState userLocationState;
@property (retain, nonatomic) NSMutableArray *items;
@property (retain, nonatomic) AdvMapViewFocusAnnotation *focusAnnotation;

@property (retain, nonatomic) NSString *searchText;
@property (retain, nonatomic) NSArray *searchResults;

@property (retain, nonatomic) id<AdvMapViewItem> selectedItem;

@end

@implementation AdvMapView

#pragma mark Init

+ (AdvMapView*)viewFromNib {
	NSArray *nibContents = [[NSBundle mainBundle] loadNibNamed:@"AdvMapView" owner:nil options:nil];
	return (AdvMapView*)[nibContents objectAtIndex:0];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self _init];
    }
    return self;
}

- (void)awakeFromNib {
	[self _init];
}

- (void)_init {
	self.userLocationState = AdvMapViewUserLocationStateOn;
	self.items = [NSMutableArray array];
	self.searchResults = [NSArray array];
	[self setupMapViewGestures];
	[self registerForKeyboardNotifications];
}

#pragma mark Memory Management

- (void)dealloc {
	[_mapView release];
	[_pagingView release];
	[_items release];
	[_searchResults release];
	[_userLocationToggleButton release];
	[_searchTableView release];
	[_searchView release];
	[_searchBar release];
	[_searchActivityIndicator release];
	[super dealloc];
}

#pragma mark Public

- (void)addItem:(id<AdvMapViewItem>)item {
	// don't re-add existing item
	if ([self.items containsObject:item]) {
		return;
	}
	
	// set the items distance
	[self updateItemDistance:item];
	
	// insert new item in order
	NSUInteger insertIndex = [self.items indexOfObject:item inSortedRange:(NSRange){0, self.items.count} options:NSBinarySearchingInsertionIndex usingComparator:^NSComparisonResult(id obj1, id obj2) {
		return [obj1 comparePriority:obj2];
	}];
	[self.items insertObject:item atIndex:insertIndex];

	// update the order values on the item and following items
	[self updateItemsOrder:insertIndex];

	// add to map
	AdvMapViewAnnotation* annotation = [[AdvMapViewAnnotation alloc] initWithItem:item];
	[self.mapView addAnnotation:annotation];
	[annotation release];
	
	// add to paging view
	[self.pagingView addItem:item];
}

- (void)removeItem:(id<AdvMapViewItem>)item {
	[self.items removeObjectAtIndex:item.order];
	
	// update order of all following items
	[self updateItemsOrder:item.order];
	
	// remove from map
	for (id<MKAnnotation> annotation in self.mapView.annotations) {
		if ([annotation isKindOfClass:[AdvMapViewAnnotation class]]) {
			AdvMapViewAnnotation* advMapViewAnnotation = (AdvMapViewAnnotation*)annotation;
			if ([advMapViewAnnotation.item isEqual:item]) {
				[self.mapView removeAnnotation:advMapViewAnnotation];
			}
		}
	}
	
	// remove from paging view
	[self.pagingView removeItem:item];
}

- (void)removeAllItems {
	while(self.items.count > 0) {
		[self removeItem:self.items[self.items.count-1]];
	}
}

- (void)removeItemsNotRelevant {
	
	// get the distance that the center of the view is away from the focus point
	CLLocation* focusLocation = [[CLLocation alloc] initWithLatitude:self.focusCoordinate.latitude longitude:self.focusCoordinate.longitude];
	CLLocation* centerLocation = [[CLLocation alloc] initWithLatitude:self.centerCoordinate.latitude longitude:self.centerCoordinate.longitude];
	CLLocationDistance distance = [centerLocation distanceFromLocation:focusLocation] + self.spanMeters;
	
	// ensure the distance isn't less than 8.5km's which is our min distance away
	if (distance < MIN_RELEVANT_DISTANCE_TO_FOCUS_METERS)
		distance = MIN_RELEVANT_DISTANCE_TO_FOCUS_METERS;
	
	// remove any items that are further away from the focus than the current view is
	// count backwards so removing items doesn't affect the indexes of the items yet to be considered
	// NOTE: we won't delete the selected item or any item closer than it
	for (int i = self.items.count - 1; i > (int)self.pagingView.selectedIndex; i--) {
		id<AdvMapViewItem> item = self.items[self.items.count-1];
		
		// once we've got within the distance, stop removing items since they are ordered closest to furthest
		if (item.distance < distance) {
			break;
		}
		
		[self removeItem:item];
	}
	
	/*
	 // removes the items off screen
	 for (id<MKAnnotation> annotation in self.mapView.annotations) {
		if ([annotation isKindOfClass:[MKUserLocation class]]) {
			continue;
		}
		
		if ([annotation isKindOfClass:[AdvMapViewAnnotation class]]) {
			AdvMapViewAnnotation* advMapViewAnnotation = (AdvMapViewAnnotation*)annotation;
			MKMapPoint point = MKMapPointForCoordinate(advMapViewAnnotation.coordinate);
			if (!MKMapRectContainsPoint(self.mapView.visibleMapRect, point)) {
				[self removeItem:advMapViewAnnotation.item];
			}
		}
	}*/
}

- (void)selectItem:(id<AdvMapViewItem>)item {
	// don't do any updating if the new selected item was the same as last time
	if (item == self.selectedItem) {
		return;
	}
	
	// cache the item selected so we can access it and determine if it's changed next time
	self.selectedItem = item;
	
	// if the pagingView isn't already selecting the item, select it
	if (self.pagingView.selectedIndex != item.order) {
		[self.pagingView scrollToItem:item animated:NO];
	}
	
	// zoom in on the new selected item
	for (id<MKAnnotation> annotation in self.mapView.annotations) {
		if ([annotation isKindOfClass:[AdvMapViewAnnotation class]]) {
			AdvMapViewAnnotation* advMapViewAnnotation = (AdvMapViewAnnotation*)annotation;
			if ([advMapViewAnnotation.item isEqual:item]) {
				[self.mapView selectAnnotation:advMapViewAnnotation animated:NO];
				[self zoomToSelected:YES];
				break;
			}
		}
	}
}

- (void)selectClosest {
	if (self.items.count > 0) {
		[self selectItem:self.items[0]];
	}
}

- (void)setFocusCoordinate:(CLLocationCoordinate2D)focusCoordinate {
	
	// default: select closest when tracking the users location
	BOOL selectClosest = self.userLocationState != AdvMapViewUserLocationStateOff;
	
	// default: zoom only when tracking the users location (but not if we're doing so with the compass!)
	BOOL zoomToSelected = self.userLocationState == AdvMapViewUserLocationStateOn;
	
	[self setFocusCoordinate:focusCoordinate selectClosest:selectClosest zoomToSelected:zoomToSelected];
	
}

- (void)setFocusCoordinate:(CLLocationCoordinate2D)focusCoordinate selectClosest:(BOOL)selectClosest zoomToSelected:(BOOL)zoomToSelected {
	
	// get rid of any previous focus annotation created by a search
	[self removeFocusAnnotation];
	
	// update the coordinate
	_focusCoordinate = focusCoordinate;
	
	// notify of the focus change
	if ([self.delegate respondsToSelector:@selector(advMapViewFocusCoordinateChanged:)]) {
		[self.delegate advMapViewFocusCoordinateChanged:self];
	}
	
	// update the state of everything that's dependent on the focus coordinate
	[self updateAllItemsDistance];
	[self.items sortUsingSelector:@selector(comparePriority:)];
	[self updateItemsOrder:0];
	[self.pagingView updateAllItems];
	
	// if specified, select the closest carpark
	if (selectClosest) {
		[self selectClosest];
	}
	
	// if specified, zoom so that the selected carpark and the focus coordinate are in view
	if (zoomToSelected) {
		[self zoomToSelected:NO];
	}
	
}

- (void)removeFocusAnnotation {
	if (self.focusAnnotation) {
		[self.mapView removeAnnotation:self.focusAnnotation];
		self.focusAnnotation = nil;
	}
}

- (CLLocationCoordinate2D)centerCoordinate {
	return self.mapView.region.center;
}

- (CGFloat)spanMeters {
	MKMapRect visibleRect = self.mapView.visibleMapRect;
	MKMapPoint minPoint = MKMapPointMake(MKMapRectGetMinX(visibleRect), MKMapRectGetMinY(visibleRect));
	MKMapPoint maxPoint = MKMapPointMake(MKMapRectGetMaxX(visibleRect), MKMapRectGetMaxY(visibleRect));
	return MKMetersBetweenMapPoints(minPoint, maxPoint);
}

- (CGFloat)accuracy {
	return self.mapView.userLocation.location.horizontalAccuracy;
}

- (void)setUserLocationState:(AdvMapViewUserLocationState)userLocationState {
	
	// dont't do anything if the values are the same
	if (_userLocationState == userLocationState) {
		return;
	}
	
	_userLocationState = userLocationState;
	switch (userLocationState) {
		case AdvMapViewUserLocationStateOff:
			[self.userLocationToggleButton setImage:[UIImage imageNamed:@"location-arrow-off"] forState:UIControlStateNormal];
			[self.mapView setUserTrackingMode:MKUserTrackingModeNone animated:YES];
			break;
		case AdvMapViewUserLocationStateOn:
			[self.userLocationToggleButton setImage:[UIImage imageNamed:@"location-arrow-on"] forState:UIControlStateNormal];
			[self.mapView setUserTrackingMode:MKUserTrackingModeNone animated:YES];
			break;
		case AdvMapViewUserLocationStateTracking:
			[self.userLocationToggleButton setImage:[UIImage imageNamed:@"location-arrow-tracking"] forState:UIControlStateNormal];
			[self.mapView setUserTrackingMode:MKUserTrackingModeFollowWithHeading animated:YES];
			break;
	}
	
	if (userLocationState >= AdvMapViewUserLocationStateOn) {
		self.focusCoordinate = self.mapView.userLocation.coordinate;
	}
}

#pragma mark Internal: Functions

- (void)moveToFocusCoordinate:(BOOL)animated {
	MKCoordinateRegion region = self.mapView.region;
	region.center = self.focusCoordinate;
	[self.mapView setRegion:region animated:animated];
}

- (void)zoomToSelected:(BOOL)animated {
	NSUInteger selectedIndex = self.pagingView.selectedIndex;
	if (self.items.count > 0) {
		id<AdvMapViewItem> selectedItem = [self.items objectAtIndex:selectedIndex];
		
		// get the visible rect
		MKMapPoint selectedPoint = MKMapPointForCoordinate(selectedItem.coordinate);
		MKMapPoint focusPoint = MKMapPointForCoordinate(self.focusCoordinate);
		
		MKMapRect selectedRect = MKMapRectMake(selectedPoint.x, selectedPoint.y, 0.1, 0.1);
		MKMapRect focusRect = MKMapRectMake(focusPoint.x, focusPoint.y, 0.1, 0.1);
		MKMapRect visibleRect = MKMapRectUnion(focusRect, selectedRect);
		UIEdgeInsets insets = UIEdgeInsetsMake(AUTO_ZOOM_MAP_INSET_TOP,AUTO_ZOOM_MAP_INSET_LEFT,AUTO_ZOOM_MAP_INSET_BOTTOM,AUTO_ZOOM_MAP_INSET_RIGHT);
		
		// convert it to a region, and bound the zoom
		MKCoordinateRegion region = MKCoordinateRegionForMapRect(visibleRect);
		if (region.span.latitudeDelta < AUTO_ZOOM_MIN_COORD_DELTA) {
			region.span.latitudeDelta = AUTO_ZOOM_MIN_COORD_DELTA;
		}
		if (region.span.longitudeDelta < AUTO_ZOOM_MIN_COORD_DELTA) {
			region.span.longitudeDelta = AUTO_ZOOM_MIN_COORD_DELTA;
		}
		
		// convert back to the visible rect after bounding
		visibleRect = MKMapRectForCoordinateRegion(region);
		
		[self.mapView setVisibleMapRect:visibleRect edgePadding:insets animated:animated];
	} else {
		[self moveToFocusCoordinate:animated];
	}
}

- (void)updateItemDistance:(id<AdvMapViewItem>)item {
	CLLocation *itemLocation = [[CLLocation alloc] initWithLatitude:item.coordinate.latitude longitude:item.coordinate.longitude];
	CLLocation *focusLocation = [[CLLocation alloc] initWithLatitude:self.focusCoordinate.latitude longitude:self.focusCoordinate.longitude];
	item.distance = [itemLocation distanceFromLocation:focusLocation];
	[itemLocation release];
	[focusLocation release];
}

- (void)updateAllItemsDistance {
	for (id<AdvMapViewItem> item in self.items) {
		[self updateItemDistance:item];
	}
}

- (void)updateItemsOrder:(NSUInteger)start {
	for (int i=start; i<self.items.count; i++) {
		id<AdvMapViewItem> item = [self.items objectAtIndex:i];
		item.order = i;
	}
}

#pragma mark Keyboard Notifications
- (void)registerForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWasShown:(NSNotification*)aNotification {
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
	
	CGRect searchViewFrame = self.searchView.frame;
	searchViewFrame.size.height -= kbSize.height;
	
	self.searchView.frame = searchViewFrame;
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
	self.searchView.frame = self.frame;
}

#pragma mark Internal: Actions

- (IBAction)userLocationToggle:(id)sender {
	[self endEditing:YES];
	
	AdvMapViewUserLocationState state = self.userLocationState + 1;
	if (state > AdvMapViewUserLocationStateTracking) {
		state = AdvMapViewUserLocationStateOff;
	}
	self.userLocationState = state;
}

#pragma mark Internal: Map Kit Delegate
- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
	
	if (self.userLocationState == AdvMapViewUserLocationStateOn || self.userLocationState == AdvMapViewUserLocationStateTracking) {
		// if we're tracking the user, set the focus coordinate as we normally would
		self.focusCoordinate = userLocation.coordinate;
	} else if (self.focusAnnotation == nil) {
		// if we're not tracking the user, only update the focus coordinate if we don't have a focus annotation defined which would be for a locked location that isn't the user location
		[self setFocusCoordinate:userLocation.coordinate selectClosest:NO zoomToSelected:NO];
	}
	
}

- (void)mapView:(MKMapView *)mapView didChangeUserTrackingMode:(MKUserTrackingMode)mode animated:(BOOL)animated {
	AdvMapViewUserLocationState state = CONVERT_FROM_MKUSERTRACKINGMODE(mode);
	if (self.userLocationState != state) {
		self.userLocationState = state;
	}
}

- (void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error {
	self.userLocationState = AdvMapViewUserLocationStateOff;
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id < MKAnnotation >)annotation {
	if ([annotation isKindOfClass:[AdvMapViewAnnotation class]]) {
		MKAnnotationView *annoView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@""];
		annoView.image = self.imagePin;
		return [annoView autorelease];
	} else if ([annotation isKindOfClass:[AdvMapViewFocusAnnotation class]]) {
		MKPinAnnotationView *pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@""];
		pinView.pinColor = MKPinAnnotationColorGreen;
		pinView.canShowCallout = YES;
		return [pinView autorelease];
	}
	
	return nil;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
	if ([view.annotation isKindOfClass:[AdvMapViewAnnotation class]]) {
		AdvMapViewAnnotation *annotation = (AdvMapViewAnnotation*)view.annotation;
		
		MKCircle* circle = [MKCircle circleWithCenterCoordinate:annotation.coordinate radius:ANNOTATION_HIGHLIGHT_CIRCLE_RADIUS_METERS];
		[mapView removeOverlays:mapView.overlays];
		[mapView addOverlay:circle];
		
		if (self.pagingView.selectedIndex != annotation.item.order) {
			self.selectedItem = annotation.item;
			[self.pagingView scrollToItem:annotation.item animated:YES];
		}
		return;
	}
}

- (MKOverlayView *)mapView:(MKMapView *)_mapView viewForOverlay:(id < MKOverlay >)overlay {
	MKCircleView *circleView = [[MKCircleView alloc] initWithCircle:(MKCircle *)overlay];
	circleView.fillColor = [[UIColor blueColor] colorWithAlphaComponent:ANNOTATION_HIGHLIGHT_CIRCLE_LINE_COLOR_ALPHA];
    circleView.strokeColor = [UIColor blueColor];
	circleView.lineWidth = ANNOTATION_HIGHLIGHT_CIRCLE_LINE_WIDTH;
    return [circleView autorelease];
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
	/*BOOL updateRegion = NO;
	MKCoordinateRegion region = mapView.region;
	if (region.span.latitudeDelta > MAX_ZOOM_OUT) {
		region.span.latitudeDelta = MAX_ZOOM_OUT;
		updateRegion = YES;
	}
	if (region.span.longitudeDelta > MAX_ZOOM_OUT) {
		region.span.longitudeDelta = MAX_ZOOM_OUT;
		updateRegion = YES;
	}
	
	if (updateRegion) {
		[mapView setRegion:region animated:YES];
	}*/
	
	if ([self.delegate respondsToSelector:@selector(advMapView:regionDidChangeAnimated:)]) {
		[self.delegate advMapView:self regionDidChangeAnimated:animated];
	}
	
	[self removeItemsNotRelevant];
	
	[self.pagingView updateAllItems];
}

#pragma mark Internal: Search Bar Delegate

- (void)searchFor:(NSString*)searchText inlineSearch:(BOOL)inlineSearch {
	if (!inlineSearch) {
		self.searchResults = [NSArray array];
		[self.searchTableView reloadData];
	}
	
	if (searchText.length > 0) {
		if (self.searchResults.count == 0) {
			[self.searchActivityIndicator startAnimating];
		}
		
		CLGeocoder *geocoder = [[[CLGeocoder alloc] init] autorelease];
		[geocoder geocodeAddressString:searchText inRegion:self.region completionHandler:^(NSArray *placemarks, NSError *error) {
			
			[self.searchActivityIndicator stopAnimating];

			if (!inlineSearch) {
				if (error) {
					NSLog(@"%@", error);
					UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"There was an error retrieving location results. Please try again later, thank you!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
					[alertView show];
					[alertView release];
					return;
				}

				if ([placemarks count] == 0) {
					UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"No results" message:@"No results could be found for the location you entered." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
					[alertView show];
					[alertView release];
					return;
				}
			}

			// update the search results
			self.searchResults = placemarks;
			[self.searchTableView reloadData];
		}];
	}
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
	if(![searchBar isFirstResponder]) {
        self.searchBarShouldBeginEditing = NO;
		self.searchText = @"";
		[self removeAllItems];
		self.focusCoordinate = self.mapView.userLocation.coordinate;
		[self moveToFocusCoordinate:NO];
		self.userLocationToggleButton.hidden = NO;
		self.searchResults = [NSArray array];
		[self.searchTableView reloadData];
		return;
    }
	
	[self searchFor:searchBar.text inlineSearch:YES];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
	BOOL shouldBeginEditing = self.searchBarShouldBeginEditing;
	self.searchBarShouldBeginEditing = YES;
	return shouldBeginEditing;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
	[self setSearchResultsViewState:YES];
	self.userLocationToggleButton.hidden = YES;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
	// this is a hack, the cancel button disables itself, so this resets it to enabled
	for(id subview in [searchBar subviews])
	{
		if ([subview isKindOfClass:[UIButton class]]) {
			dispatch_async(dispatch_get_main_queue(), ^(void){
				[subview setEnabled:YES];
			});
		}
	}
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
	if (![self.searchBar.text isEqualToString:self.searchText]) {
		self.searchBar.text = self.searchText;
		self.searchResults = [NSArray array];
		[self.searchTableView reloadData];
	}
	[self setSearchResultsViewState:NO];
	[self endEditing:YES];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
	[self endEditing:YES];
}

#pragma mark Table View Data Source (Search Results)

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.searchResults.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell;
	
	if (indexPath.row == 0) {
		static NSString *cellIdentifier = @"currentloc";
		cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
			cell.textLabel.textColor = [UIColor colorWithRed:0 green:136.0/255.0 blue:247.0/255.0 alpha:1];
			cell.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"info-bar-bg.png"]] autorelease];
		}
		cell.textLabel.text = @"Current Location";
	} else {
		static NSString *cellIdentifier = @"row";
		cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier] autorelease];
		}
		CLPlacemark *placemark = self.searchResults[indexPath.row - 1];
		cell.textLabel.text = placemark.title;
		cell.detailTextLabel.text = placemark.subtitle;
	}
	
	return cell;
}

#pragma mark Table View Delegate (Search Results)
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	[self endEditing:YES];
	
	// reset the paging view to zero
	[self.pagingView scrollToIndex:0 animated:NO];
	
	// remove any existing items as we're about to change focus
	[self removeAllItems];
	
	if (indexPath.row == 0) {
		self.searchText = @"";
		self.searchBar.text = @"";
		self.userLocationState = AdvMapViewUserLocationStateOn;
		self.searchResults = [NSArray array];
		[self.searchTableView reloadData];
	} else {
		self.searchText = self.searchBar.text;
		
		self.userLocationState = AdvMapViewUserLocationStateOff;
		
		CLPlacemark *placemark = self.searchResults[indexPath.row-1];
		
		// update focus coord
		self.focusCoordinate = placemark.location.coordinate;
		
		// add an annotation to the map for the search
		self.focusAnnotation = [[[AdvMapViewFocusAnnotation alloc] initWithPlacemark:placemark] autorelease];
		[self.mapView addAnnotation:self.focusAnnotation];
		
		// display the annotation view for the focus point
		[self.mapView selectAnnotation:self.focusAnnotation animated:YES];
	}
	
	[self setSearchResultsViewState:NO];
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (void)setSearchResultsViewState:(BOOL)visible {
	self.searchView.hidden = !visible;
	[self.searchBar setShowsCancelButton:visible animated:YES];
	self.userLocationToggleButton.hidden = self.searchBar.text.length != 0;
}


#pragma mark Internal: AdvMapViewPagingView Delegate

- (void)advMapViewPagingViewSelectedItemUpdate:(AdvMapViewPagingView*)pagingView {
	
	// check that we actually have items to select (it can fire with zero and no items)
	int selectedIndex = self.pagingView.selectedIndex;
	if (self.items.count > selectedIndex) {
		
		// get the new item that's selected from the list
		id<AdvMapViewItem> selectedItem = [self.items objectAtIndex:selectedIndex];
		
		[self selectItem:selectedItem];
		
	}
	
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	
	// check that we actually have items to select (it can fire with zero and no items)
	int selectedIndex = self.pagingView.selectedIndex;
	if (self.items.count > selectedIndex) {
		
		// if the selected item has been changed manually by the user, turn tracking off
		self.userLocationState = AdvMapViewUserLocationStateOff;

		// other than the above, do the same things as if we've been told the selected item has been updated
		[self advMapViewPagingViewSelectedItemUpdate:(AdvMapViewPagingView*)scrollView];
		
	}
	
}

#pragma mark Internal: Map Guester Tracking
- (void)setupMapViewGestures {
	// track when the user pans the map
    UIPanGestureRecognizer* panRec = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(mapViewManuallyMoved:)];
    [panRec setDelegate:self];
    [self.mapView addGestureRecognizer:panRec];
	
	// track when user pinches map to change zoom
    UIPinchGestureRecognizer* pinchRec = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(mapViewManuallyMoved:)];
    [pinchRec setDelegate:self];
    [self.mapView addGestureRecognizer:pinchRec];
	
	// track when user double taps map to zoom in
	UITapGestureRecognizer* zoomRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mapViewManuallyMoved:)];
	zoomRec.numberOfTapsRequired = 2;
    [zoomRec setDelegate:self];
    [self.mapView addGestureRecognizer:zoomRec];
	
	// track when user single taps map
	UITapGestureRecognizer* tapRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mapViewTapped:)];
	tapRec.numberOfTapsRequired = 1;
    [tapRec setDelegate:self];
    [self.mapView addGestureRecognizer:tapRec];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)mapViewManuallyMoved:(UIGestureRecognizer*)gestureRecognizer {
	if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
		self.userLocationState = AdvMapViewUserLocationStateOff;
	}
}

- (void)mapViewTapped:(UIGestureRecognizer*)gestureRecognizer {
	[self endEditing:YES];
}

@end
