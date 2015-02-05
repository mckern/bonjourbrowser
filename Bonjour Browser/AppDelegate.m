//
//  AppDelegate.m
//  Bonjour Browser
//
//  Created by PHPdev32 on 9/5/12.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

#import "AppDelegate.h"
#import "masterBrowser.h"

@implementation AppDelegate {
    __unsafe_unretained IBOutlet NSBrowser *_browser;
}

#pragma mark Application Delegate
-(void)awakeFromNib {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults registerDefaults:@{@"tabIndex": @0, @"resolveNames": @NO}];
    [defaults addObserver:self forKeyPath:@"tabIndex" options:0 context:nil];
    [defaults addObserver:self forKeyPath:@"resolveNames" options:0 context:nil];
}

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    muteWithNotice(self, master, [_master = [masterBrowser new] fetch]);
    NSView *view = [[_browser.superview.subviews.lastObject subviews] firstObject];
    [(NSTableView *)view.subviews.lastObject setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"key" ascending:true selector:@selector(localizedStandardCompare:)], [NSSortDescriptor sortDescriptorWithKey:@"value" ascending:true selector:@selector(localizedStandardCompare:)]]];
}

-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return true;
}

-(void)applicationWillTerminate:(NSNotification *)notification {
    [_master halt];
}

#pragma mark Observations
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"tabIndex"])
        [_browser reloadColumn:0];
    else if ([keyPath isEqualToString:@"resolveNames"])
        muteWithNotice([[[_browser selectedCellInColumn:0] representedObject] representedObject], children,);
}

#pragma mark GUI
-(IBAction)copy:(id)sender {
    NSResponder *obj = [[NSApp keyWindow] firstResponder];
    if ([obj isKindOfClass:NSTableView.class]) {
        if (![(NSTableView *)obj numberOfSelectedRows]) return;
        bool viewBased = ([(NSTableView *)obj rowViewAtRow:[(NSTableView *)obj selectedRow] makeIfNecessary:false]);
        __block NSMutableArray *rows = [NSMutableArray array];
        [[(NSTableView *)obj selectedRowIndexes] enumerateIndexesUsingBlock:^void(NSUInteger idx, BOOL *stop){
            NSUInteger i = 0, j = [(NSTableView *)obj numberOfColumns];
            NSMutableArray *row = [NSMutableArray array];
            if (viewBased) {
                NSText *view;
                while (i < j)
                    if ((view = [(NSTableView *)obj viewAtColumn:i++ row:idx makeIfNecessary:false]) && [view isKindOfClass:NSText.class])
                        [row addObject:[view.string stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]];
            }
            else {
                NSCell *cell;
                while (i < j)
                    if ((cell = [(NSTableView *)obj preparedCellAtColumn:i++ row:idx]) && [cell isKindOfClass:NSTextFieldCell.class])
                        [row addObject:[cell.stringValue stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]];
            }
            [row removeObject:@""];
            [rows addObject:[row componentsJoinedByString:@", "]];
        }];
        [NSPasteboard.generalPasteboard clearContents];
        [NSPasteboard.generalPasteboard writeObjects:@[[rows componentsJoinedByString:@"\n"]]];
    }
}

-(IBAction)choose:(id)sender {
    [[[[sender selectedCell] representedObject] representedObject] fetch];
}

@end
