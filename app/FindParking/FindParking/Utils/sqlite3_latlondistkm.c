//
//  sqlite_latlondistkm.c
//
//  Created by Leigh McCulloch on 15/03/13.
//  Copyright (c) 2013 Leigh McCulloch. All rights reserved.
//

#include "sqlite3_latlondistkm.h"
#include <math.h>

#define EARTH_RADIUS_KM 6367

void sqlite3_latlondistkm(sqlite3_context *context, int argc, sqlite3_value **argv) {
	// ref: http://mathforum.org/library/drmath/view/51879.html
	//   dlon = lon2 - lon1
	//   dlat = lat2 - lat1
	//   a = (sin(dlat/2))^2 + cos(lat1) * cos(lat2) * (sin(dlon/2))^2
	//   c = 2 * atan2(sqrt(a), sqrt(1-a))
	//   d = R * c
	
    if (argc == 4) {
        double lat1 = sqlite3_value_double(argv[0]) * M_PI / 180.0;
        double lon1 = sqlite3_value_double(argv[1]) * M_PI / 180.0;
        double lat2 = sqlite3_value_double(argv[2]) * M_PI / 180.0;
        double lon2 = sqlite3_value_double(argv[3]) * M_PI / 180.0;
		
		double lat = lat2 - lat1;
		double lon = lon2 - lon1;
		
		double a = pow(sin(lat / 2.0), 2.0) + (cos(lat1) * cos(lat2) * pow(sin(lon / 2.0), 2.0));
		//double c = 2.0 * asin(sqrt(a));
		double c = 2.0 * atan2(sqrt(a), sqrt(1-a));
		
		double distance = c * EARTH_RADIUS_KM;
		
		sqlite3_result_double(context, distance);
		return;
    }
    sqlite3_result_null(context);
}