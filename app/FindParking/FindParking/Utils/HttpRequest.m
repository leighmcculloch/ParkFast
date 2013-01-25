//
//  HttpRequest.m
//  FindParking
//
//  Created by Leigh McCulloch on 25/01/13.
//  Copyright (c) 2013 Leigh McCulloch. All rights reserved.
//

#import "HttpRequest.h"

@interface HttpRequest() {
    dispatch_queue_t requestQueue;
}

@end

@implementation HttpRequest

+(NSData*)getDataFromURL:(NSString *)url {
    NSError* error = nil;
    NSURL* urlObj = [NSURL URLWithString:url];
    NSURLRequest* request = [NSURLRequest requestWithURL:urlObj];
    NSURLResponse* response = nil;
    NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	if (error) {
		NSLog(@"%@", error);
		return nil;
	}
    return data;
}

-(id)init {
    if ((self = [super init])) {
		requestQueue = dispatch_queue_create(NULL, NULL);
	}
	return self;
}

-(void)getDataFromURL:(NSString*)url andCallback:(HttpRequestCallbackWithData)callback {
	dispatch_async(requestQueue, ^{
		NSData* data = [HttpRequest getDataFromURL:url];
		if (callback) {
			dispatch_queue_t mq = dispatch_get_main_queue();
			dispatch_async(mq, ^{
				callback(url, data);
			});
		}
	});
}

-(void)getStringFromURL:(NSString*)url andCallback:(HttpRequestCallbackWithString)callback {
	[self getDataFromURL:url andCallback:^(NSString *url, NSData *data) {
		if (callback) {
			NSString* dataStr = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
			callback(url, dataStr);
		}
	}];
}

-(void)getJsonFromURL:(NSString*)url andCallback:(HttpRequestCallbackWithDictionary)callback {
	[self getDataFromURL:url andCallback:^(NSString *url, NSData *data) {
		if (callback) {
			if (!data) {
				callback(url, nil);
				return;
			}
			
			NSError *jsonError = nil;
			NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
			if (jsonError) {
				callback(url, nil);
				return;
			}
			callback(url, dictionary);
		}
	}];
}

-(void)dealloc {
    dispatch_release(requestQueue);
    [super dealloc];
}

@end
