//
//  FPInfoView.m
//  FindParking
//
//  Created by Leigh McCulloch on 18/01/13.
//  Copyright (c) 2013 Leigh McCulloch. All rights reserved.
//

#import "AdvMapViewInfoView.h"
#import <MapKit/MapKit.h>

@interface AdvMapViewInfoView()

@property (retain, nonatomic) IBOutlet UILabel *labelTitle;
@property (retain, nonatomic) IBOutlet UILabel *labelSubtitle1;
@property (retain, nonatomic) IBOutlet UILabel *labelSubtitle2;
@property (retain, nonatomic) IBOutlet UILabel *labelDistance;

@end

@implementation AdvMapViewInfoView

+ (AdvMapViewInfoView*)infoViewWithItem:(id<AdvMapViewItem>)item {
	NSArray *nibContents = [[NSBundle mainBundle] loadNibNamed:@"AdvMapViewInfoView" owner:nil options:nil];
	AdvMapViewInfoView *infoView = (AdvMapViewInfoView*)[nibContents objectAtIndex:0];
	infoView.item = item;
    return infoView;
}

- (void)setItem:(id<AdvMapViewItem>)item	{
	_item = item;
	[self updateLabels];
}

- (void)updateLabels {
	self.labelTitle.text = self.item.title;
	self.labelSubtitle1.text = self.item.subtitle1;
	self.labelSubtitle2.text = self.item.subtitle2;
	self.labelDistance.text = [NSString stringWithFormat:@"%.1fkm", self.item.distance/1000.0];
}

- (IBAction)showDirections:(id)sender {
	BOOL supportsGoogleMaps = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:[NSString stringWithFormat:@"comgooglemaps://"]]];
	if (supportsGoogleMaps) {
		NSString* title = @"Which app would you like to navigate you?";
		UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Apple Maps", @"Google Maps", nil];
		actionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
		[actionSheet showInView:self];
	} else {
		[self navigateWithNative];
	}
}

- (void)navigateWithGoogleMaps {
	NSURL* mapUrl = [NSURL URLWithString:[NSString stringWithFormat:@"comgooglemaps://?saddr=&daddr=%f,%f&directionsmode=driving", self.item.coordinate.latitude, self.item.coordinate.longitude]];
	[[UIApplication sharedApplication] openURL:mapUrl];
}

- (void)navigateWithNative {
	MKPlacemark* place = [[MKPlacemark alloc] initWithCoordinate:self.item.coordinate addressDictionary:nil];
    MKMapItem* destination = [[MKMapItem alloc] initWithPlacemark:place];
    destination.name = self.item.title;
    NSArray* items = [[NSArray alloc] initWithObjects: destination, nil];
    NSDictionary* options = [[NSDictionary alloc] initWithObjectsAndKeys: MKLaunchOptionsDirectionsModeDriving, MKLaunchOptionsDirectionsModeKey, nil];
    [MKMapItem openMapsWithItems:items launchOptions:options];
}

#pragma -- Action Sheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	switch (buttonIndex) {
		case 0:
			[self navigateWithNative];
			break;
		case 1:
			[self navigateWithGoogleMaps];
			break;
	}
}


- (void)dealloc {
	[_labelTitle release];
	[_labelSubtitle1 release];
	[_labelSubtitle2 release];
	[_labelDistance release];
	[super dealloc];
}
@end
