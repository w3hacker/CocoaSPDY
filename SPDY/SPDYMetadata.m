//
//  SPDYMetadata.m
//  SPDY
//
//  Copyright (c) 2014 Twitter, Inc. All rights reserved.
//  Licensed under the Apache License v2.0
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Created by Michael Schore
//

#import <objc/runtime.h>
#import "SPDYCommonLogger.h"
#import "SPDYMetadata.h"
#import "SPDYProtocol.h"
#import "SPDYStopwatch.h"

static const char *kMetadataAssociatedObjectKey = "SPDYMetadataAssociatedObject";

@implementation SPDYMetadata

/**
  Note about the SPDYMetadata identifier:

  This provides a mechanism for the metadata to be retrieved by the application at any point
  during processing of a request (well, after receiving the response or error). The application
  can request the metadata multiple times if it wants to track progress, or else wait until the
  connectionDidFinishLoading callback to get the final metadata.

  This is achieved by associating an instance of SPDYMetadata with an NSString instance used
  as the identifier. As long as that identifier is alive, the metadata will be available.
*/

static NSString * const SPDYMetadataIdentifierKey = @"x-spdy-metadata-identifier";

- (id)init
{
    self = [super init];
    if (self) {
        _version = @"3.1";
        _latencyMs = -1;
    }
    return self;
}

- (NSDictionary *)dictionary
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:@{
        SPDYMetadataVersionKey : _version,
        SPDYMetadataStreamTxBytesKey : [@(_txBytes) stringValue],
        SPDYMetadataStreamRxBytesKey : [@(_rxBytes) stringValue],
        SPDYMetadataStreamConnectedMsKey : [@(_connectedMs) stringValue],
        SPDYMetadataStreamBlockedMsKey : [@(_blockedMs) stringValue],
        SPDYMetadataSessionViaProxyKey : [@(_viaProxy) stringValue],
        SPDYMetadataSessionProxyStatusKey : [@(_proxyStatus) stringValue],
    }];

    if (_streamId > 0) {
        dict[SPDYMetadataStreamIdKey] = [@(_streamId) stringValue];
    }

    if (_latencyMs > -1) {
        dict[SPDYMetadataSessionLatencyKey] = [@(_latencyMs) stringValue];
    }

    if ([_hostAddress length] > 0) {
        dict[SPDYMetadataSessionRemoteAddressKey] = _hostAddress;
        dict[SPDYMetadataSessionRemotePortKey] = [@(_hostPort) stringValue];
    }

    return dict;
}

+ (void)setMetadata:(SPDYMetadata *)metadata forAssociatedDictionary:(NSMutableDictionary *)dictionary
{
    // We need to create a new instance of each identifier we assign to a dictionary. The value
    // of the identifier doesn't actually matter, but a unique one is useful for debugging.
    CFAbsoluteTime timestamp = CFAbsoluteTimeGetCurrent();
    NSString *identifier = [NSString stringWithFormat:@"%f/%tx", timestamp, (NSUInteger)metadata];
    objc_setAssociatedObject(identifier, kMetadataAssociatedObjectKey, metadata, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    dictionary[SPDYMetadataIdentifierKey] = identifier;
}

+ (SPDYMetadata *)metadataForAssociatedDictionary:(NSDictionary *)dictionary;
{
    NSString *identifier = dictionary[SPDYMetadataIdentifierKey];
    if (identifier.length > 0) {
        id associatedObject = objc_getAssociatedObject(identifier, kMetadataAssociatedObjectKey);
        if ([associatedObject isKindOfClass:[SPDYMetadata class]]) {
            return associatedObject;
        }
    }
    return nil;
}

@end
