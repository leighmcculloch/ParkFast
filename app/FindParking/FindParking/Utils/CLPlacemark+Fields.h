//
//  CLPlacemark+Fields.h
//  FindParking
//
//  Created by Leigh McCulloch on 12/04/13.
//  Copyright (c) 2013 Leigh McCulloch. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@interface CLPlacemark (Fields)

@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *subtitle;

@end
