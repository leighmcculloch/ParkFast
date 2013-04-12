//
//  AdvMapViewSearchBar.m
//  FindParking
//
//  Created by Leigh McCulloch on 25/01/13.
//  Copyright (c) 2013 Leigh McCulloch. All rights reserved.
//

#import "AdvMapViewSearchBar.h"
#import "UIImage+imageWithColor.h"

@interface AdvMapViewSearchBar ()

@property (retain, nonatomic) UIColor *originalPlaceholderTextColor;
@property (retain, nonatomic) UIImage *originalBackgroundImage;

@end

@implementation AdvMapViewSearchBar

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
	self.backgroundVisible = NO;
	self.originalPlaceholderTextColor = self.placeholderTextColor;
}

- (void)setBackgroundVisible:(BOOL)backgroundVisible {
	if (backgroundVisible) {
		self.backgroundImage = self.originalBackgroundImage;
	} else {
		self.originalBackgroundImage = self.backgroundImage;
		self.backgroundImage = [UIImage imageWithColor:[UIColor clearColor]];
	}
	_backgroundVisible = backgroundVisible;
}

- (void)setPlaceholderTextColor:(UIColor *)placeholderTextColor {
	UITextField *searchField = [self valueForKey:@"_searchField"];
	[searchField setValue:placeholderTextColor forKeyPath:@"_placeholderLabel.textColor"];
}

- (UIColor*)placeholderTextColor {
	UITextField *searchField = [self valueForKey:@"_searchField"];
	return (UIColor*)[searchField valueForKeyPath:@"_placeholderLabel.textColor"];
}

- (void)resetPlaceholderTextColor {
	self.placeholderTextColor = self.originalPlaceholderTextColor;
}

@end
