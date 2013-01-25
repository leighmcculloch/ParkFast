//
//  FPHTTPGet.h
//  FindParking
//
//  Created by Leigh McCulloch on 15/01/13.
//  Copyright (c) 2013 Leigh McCulloch. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^HttpRequestCallbackWithData)(NSString* url, NSData* data);
typedef void(^HttpRequestCallbackWithString)(NSString* url, NSString* str);
typedef void(^HttpRequestCallbackWithDictionary)(NSString* url, NSDictionary* json);

@interface HttpRequest : NSObject

-(id)init;

+(NSData*)getDataFromURL:(NSString*)url;

-(void)getDataFromURL:(NSString*)url andCallback:(HttpRequestCallbackWithData)callback;
-(void)getStringFromURL:(NSString*)url andCallback:(HttpRequestCallbackWithString)callback;
-(void)getJsonFromURL:(NSString*)url andCallback:(HttpRequestCallbackWithDictionary)callback;


@end
