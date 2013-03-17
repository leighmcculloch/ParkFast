//
//  MKMapRectForCoordinateRegion.h
//
//  Created by Leigh McCulloch on 17/03/13.
//  Copyright (c) 2013 Leigh McCulloch. All rights reserved.
//

#ifndef MKMapRectForCoordinateRegion_h
#define MKMapRectForCoordinateRegion_h

#import <MapKit/MapKit.h>

MKMapRect MKMapRectForCoordinateRegion(MKCoordinateRegion region) {
	CLLocationDegrees latDeltaHalf = region.span.latitudeDelta/2.0;
	CLLocationDegrees lonDeltaHalf = region.span.longitudeDelta/2.0;
	
	CLLocationDegrees topLeftLat = region.center.latitude + latDeltaHalf;
	CLLocationDegrees topLeftLon = region.center.longitude - lonDeltaHalf;
	
	CLLocationDegrees bottomRightLat = region.center.latitude - latDeltaHalf;
	CLLocationDegrees bottomRightLon = region.center.longitude + lonDeltaHalf;
	
	CLLocationCoordinate2D topLeftCoord = CLLocationCoordinate2DMake(topLeftLat, topLeftLon);
	CLLocationCoordinate2D bottomRightCoord = CLLocationCoordinate2DMake(bottomRightLat, bottomRightLon);
	
	MKMapPoint topLeftMapPoint = MKMapPointForCoordinate(topLeftCoord);
	MKMapPoint bottomRightMapPoint = MKMapPointForCoordinate(bottomRightCoord);
	
	double xDiff = bottomRightMapPoint.x - topLeftMapPoint.x;
	double yDiff = bottomRightMapPoint.y - topLeftMapPoint.y;
	
	MKMapRect mapRect = MKMapRectMake(topLeftMapPoint.x, topLeftMapPoint.y, xDiff, yDiff);
	
	return mapRect;
}

#endif
