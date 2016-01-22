//
//  PlaylistGenerator.m
//  PlaylistProject
//
//  Created by Roshan Krishnan on 1/20/16.
//  Copyright © 2016 Roshan Krishnan. All rights reserved.
//

#import "PlaylistGenerator.h"

@implementation PlaylistGenerator

- (id)init {
    self = [super init];
    if (self){
        // superclass successfully initialized, further
        // initialization happens here ...
        self.artistSearchUrl = @"http://developer.echonest.com/api/v4/artist";
        self.apiKey = @"0N9TCBWKIBVXAP0GY";
    }
    return self;
}

- (NSDictionary *)doHttpRequestWithUrl:(NSString *)urlString {
    // create an NSURL from the string
    NSURL *url = [NSURL URLWithString:urlString];
    
    // create the request
    NSURLRequest * request = [NSURLRequest requestWithURL:url];
    
    // create variables to hold response and/or error
    NSURLResponse *response;
    NSError *error;
    
    // send our request away
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    // handle possible error (poorly)
    // TODO: more robust error handling?
    if(error != nil){
        NSLog(@"Error with GET request: %@", urlString);
        return NULL;
    }
    
    // parse the JSON
    NSError *jError = nil;
    NSDictionary *jsonArray = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&jError];
    
    if (jError != nil) {
        NSLog(@"Error parsing JSON.");
        return NULL;
    }

    return jsonArray;
}


// Takes the name of an artist- returns the Echo Nest ID of that artist
-(NSString *)searchForArtistWithName:(NSString *)artist {
    // create the GET request string
    NSString *urlString = [NSString stringWithFormat:@"%@/search?api_key=%@&name=%@", self.artistSearchUrl, self.apiKey, artist];
    NSLog(@"%@", urlString);

    // do the HTTP request
    NSDictionary *result = [self doHttpRequestWithUrl:urlString];
    
    // parse the result, extracting the first artist result and getting its ID
    NSString *artistId = NULL;
    if(result != NULL){
        NSArray *artists = [[result objectForKey:@"response"] objectForKey:@"artists"];
        artistId = [artists[0] objectForKey:@"id"];
        NSMutableArray *songs = [self getArtistSongsById:artistId andName:artist];
        for(Song *s in songs){
            NSLog(@"Artist: %@\nTitle: %@\nUUID: %@\n", s.artist, s.title, s.UUID);
        }
        //NSLog(@"%@", artistId);
    }
    return artistId;
}

// return all songs that contain featured artists
- (NSMutableArray *)getArtistSongsById:(NSString *)artistId andName:(NSString *)artistName {
    if(artistId == NULL)
        return NULL;
    
    NSArray *songs = NULL;
    NSMutableArray *songsWithFeatured = [[NSMutableArray alloc] init];
    
    for(int i = 0; i <= 300; i += 100){
        // create the GET request string
        NSString *urlString = [NSString stringWithFormat:@"%@/songs?api_key=%@&id=%@&format=json&start=%d&results=100", self.artistSearchUrl, self.apiKey, artistId, i];
        NSLog(@"%@", urlString);
        
        // do the HTTP request
        NSDictionary *result = [self doHttpRequestWithUrl:urlString];
        if(result != NULL){
            songs = [[result objectForKey:@"response"] objectForKey:@"songs"];
            //NSLog(@"%@", songs);
            // get the songs that contain featured artists
            for(NSObject *song in songs){
                NSString *title = [song valueForKey:@"title"];
                NSString *uuid = [song valueForKey:@"id"];
                NSUInteger feat = [title rangeOfString:@"feat." options:NSCaseInsensitiveSearch].location;
                NSUInteger featuring = [title rangeOfString:@"featuring" options:NSCaseInsensitiveSearch].location;
                
                // if an artist is featured, add it to the mutable array
                if(feat != NSNotFound || featuring != NSNotFound){
                    Song *newSong = [[Song alloc] initWithTitle:title Artist:artistName andUUID:uuid];
                    [songsWithFeatured addObject:newSong];
                }
            }
        }
    }
    
    return songsWithFeatured;
}

// helper function that returns an array of song titles in string format
- (NSMutableArray *)getSongTitles:(NSArray *)songs {
    NSMutableArray *titles = [[NSMutableArray alloc] init];
    if(songs == NULL)
        return NULL;
    for(NSObject *obj in songs){
        NSString *title = [obj valueForKey:@"title"];
        [titles addObject:[NSString stringWithFormat:@"%@", title]];
    }
    return titles;
}

- (NSMutableArray *)getFeaturedArtists:(NSMutableArray *)songTitles {
    if(songTitles == NULL)
        return NULL;
    for(NSString *title in songTitles){
        int location = [title rangeOfString:@"feat." options:NSCaseInsensitiveSearch].location;
        if(location != NSNotFound){
        
        }
    }
    return NULL;
}

- (NSMutableArray *)generatePlaylist:(NSString *)artist withLength:(int)size {
    // create the empty playlist array
    NSMutableArray *playlist = [[NSMutableArray alloc] init];
    
    // create a local variable to store the current artist in
    NSString *currentArtist = artist;
    
    for(int i = 0; i < size; i++){
        NSString *artistId = [self searchForArtistWithName:currentArtist];
        NSMutableArray *songs = [self getArtistSongsById:artistId andName:currentArtist];
        NSMutableArray *featured = [self getFeaturedArtists:[self getSongTitles:songs]];
    }
    return NULL;
}

@end
