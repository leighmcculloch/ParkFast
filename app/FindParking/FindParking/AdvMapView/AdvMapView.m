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
@property (assign, nonatomic) AdvMapViewUserLocationState userLocationState;
@property (retain, nonatomic) NSMutableArray *items;
@property (retain, nonatomic) AdvMapViewFocusAnnotation *focusAnnotation;

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
	[self setupMapViewGestures];
}

#pragma mark Memory Management

- (void)dealloc {
	[_mapView release];
	[_pagingView release];
	[_items release];
	[_userLocationToggleButton release];
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

- (void)removeItemsOffScreen {
	/*for (id<MKAnnotation> annotation in self.mapView.annotations) {
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

- (void)setFocusCoordinate:(CLLocationCoordinate2D)focusCoordinate {
	// get rid of any previous focus annotation created by a search
	if (self.focusAnnotation) {
		[self.mapView removeAnnotation:self.focusAnnotation];
		self.focusAnnotation = nil;
	}
	_focusCoordinate = focusCoordinate;
	[self updateAllItemsDistance];
	[self.items sortUsingSelector:@selector(comparePriority:)];
	[self updateItemsOrder:0];
	if (self.userLocationState != AdvMapViewUserLocationStateTracking) {
		[self zoomToSelected];
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

- (void)moveToFocusCoordinate {
	MKCoordinateRegion region = self.mapView.region;
	region.center = self.focusCoordinate;
	[self.mapView setRegion:region animated:YES];
}

- (void)zoomToSelected {
	NSUInteger selectedIndex = self.pagingView.selectedIndex;
	if (self.items.count > 0) {
		id<AdvMapViewItem> selectedItem = [self.items objectAtIndex:selectedIndex];

		MKMapPoint selectedPoint = MKMapPointForCoordinate(selectedItem.coordinate);
		MKMapPoint focusPoint = MKMapPointForCoordinate(self.focusCoordinate);
		
		MKMapRect selectedRect = MKMapRectMake(selectedPoint.x, selectedPoint.y, 0.1, 0.1);
		MKMapRect focusRect = MKMapRectMake(focusPoint.x, focusPoint.y, 0.1, 0.1);
		MKMapRect visibleRect = MKMapRectUnion(focusRect, selectedRect);
		UIEdgeInsets insets = UIEdgeInsetsMake(100.0,40.0,60.0,40.0);
		
		[self.mapView setVisibleMapRect:visibleRect edgePadding:insets animated:YES];
	} else {
		[self moveToFocusCoordinate];
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
		self.focusCoordinate = userLocation.coordinate;
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
		
		MKCircle* circle = [MKCircle circleWithCenterCoordinate:annotation.coordinate radius:100.0];
		[mapView removeOverlays:mapView.overlays];
		[mapView addOverlay:circle];
		
		if (self.pagingView.selectedIndex != annotation.item.order) {
			[self.pagingView scrollToItem:annotation.item animated:YES];
		}
		return;
	}
}

- (MKOverlayView *)mapView:(MKMapView *)_mapView viewForOverlay:(id < MKOverlay >)overlay {
	MKCircleView *circleView = [[MKCircleView alloc] initWithCircle:(MKCircle *)overlay];
	circleView.fillColor = [[UIColor blueColor] colorWithAlphaComponent:0.2f];
    circleView.strokeColor = [UIColor blueColor];
	circleView.lineWidth = 6.0f;
    return [circleView autorelease];
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
	BOOL updateRegion = NO;
	MKCoordinateRegion region = mapView.region;
	if (region.span.latitudeDelta > 0.05) {
		region.span.latitudeDelta = 0.05;
		updateRegion = YES;
	}
	if (region.span.longitudeDelta > 0.05) {
		region.span.longitudeDelta = 0.05;
		updateRegion = YES;
	}
	
	if (updateRegion) {
		[mapView setRegion:region animated:YES];
	}
	
	if ([self.delegate respondsToSelector:@selector(advMapView:regionDidChangeAnimated:)]) {
		[self.delegate advMapView:self regionDidChangeAnimated:animated];
	}
	
	[self removeItemsOffScreen];
}

#pragma mark Internal: Search Bar Delegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
	self.userLocationToggleButton.hidden = searchText.length > 0;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
	
	[self endEditing:YES];
	if (searchBar.text.length > 0) {
		self.userLocationState = AdvMapViewUserLocationStateOff;
		
		CLGeocoder *geocoder = [[[CLGeocoder alloc] init] autorelease];
		[geocoder geocodeAddressString:searchBar.text completionHandler:^(NSArray *placemarks, NSError *error) {
			if (error) {
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
			
			CLPlacemark *placemark = [placemarks objectAtIndex:0];
			self.focusCoordinate = placemark.location.coordinate;
			
			// add an annotation to the map for the search
			self.focusAnnotation = [[[AdvMapViewFocusAnnotation alloc] initWithPlacemark:placemark] autorelease];
			[self.mapView addAnnotation:self.focusAnnotation];
		}];
	}
}

#pragma mark Internal: AdvMapViewPagingView Delegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	id<AdvMapViewItem> selectedItem = [self.items objectAtIndex:self.pagingView.selectedIndex];
	for (id<MKAnnotation> annotation in self.mapView.annotations) {
		if ([annotation isKindOfClass:[AdvMapViewAnnotation class]]) {
			AdvMapViewAnnotation* advMapViewAnnotation = (AdvMapViewAnnotation*)annotation;
			if ([advMapViewAnnotation.item isEqual:selectedItem]) {
				[self.mapView selectAnnotation:advMapViewAnnotation animated:NO];
				[self zoomToSelected];
				break;
			}
		}
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
