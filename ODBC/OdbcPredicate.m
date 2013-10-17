//
//  OdbcPredicate.m
//  TestParseKit
//
//  Created by Mikael Hakman on 2013-10-14.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

static NSString * GrammarFileName = @"OdbcPredicate";
static NSString * GrammarFileType = @"grammar";

#import "OdbcPredicate.h"

#import <Odbc/Odbc.h>
#import <ParseKit/ParseKit.h>

@interface OdbcPredicate () {
    
    NSMutableString * sql;    
}

@property NSString * grammar;

@property PKParseTree * parseTree;

@end

@implementation OdbcPredicate

@synthesize grammar;

@synthesize parseTree;
//
// Main methods
//
- (NSString *) genSqlFromPredicate : (NSPredicate *) pred {
    
    return [self genSqlFromString : pred.predicateFormat];
}

- (NSString *) genSqlFromString : (NSString *) input {
    
    [self parse : input];

    NSAssert (self.parseTree.children.count == 1,@"");

    self->sql = [NSMutableString stringWithFormat : @"where"];
    
    PKRuleNode * predicate = self.parseTree.children [0];
    
    [self genPredicate : predicate];
    
    return self->sql;
}

- (PKParseTree *) parse : (NSString *) input {
    
    PKParseTreeAssembler * pta = [PKParseTreeAssembler new];
    
    PKParser * parser = [[PKParserFactory factory ] parserFromGrammar : self.grammar
                                                            assembler : pta
                                                         preassembler : pta
                                                                error : nil];
    if (! parser) {
        
        RAISE_ODBC_EXCEPTION(__PRETTY_FUNCTION__,"Cannot create parser");
    }
    
    self.parseTree = [parser parse : input error : nil];
    
    if (! parseTree) {
        
        NSString * msg = [NSString stringWithFormat : @"Invalid or unsupported predicate '%@'",input];
        
        RAISE_ODBC_EXCEPTION(__PRETTY_FUNCTION__,msg.UTF8String);
    }
    
    return self.parseTree;
}

- (NSString *) grammar {
    
    if (self->grammar) return self->grammar;
    
    NSError * error;
    
    NSBundle * bundle = [NSBundle bundleForClass : [self class]];
    
    NSString * grammarFilePath = [bundle pathForResource : GrammarFileName ofType : GrammarFileType];
    
    self->grammar =
    
    [NSString stringWithContentsOfFile : grammarFilePath encoding : NSUTF8StringEncoding error : &error];
    
    if (! grammar || error) {
        
        NSString * msg = [NSString stringWithFormat : @"Cannot find file %@",grammarFilePath];
        
        RAISE_ODBC_EXCEPTION (__PRETTY_FUNCTION__,msg.UTF8String);
    }
    
    return self->grammar;
}
//
// Compound predicates
//
- (void) genPredicate : (PKRuleNode *) predicate{
    
    NSAssert (predicate.children.count == 1,@"");
    
    [self genOrPred : predicate.children[0]];
}

- (void) genOrPred : (PKRuleNode *) orPred {
    
    NSAssert (orPred.children.count >= 1,@"");
    
    [self genAndPred : orPred.children[0]];
    
    for (int i = 1; i < orPred.children.count; i++) {
        
        [self genOrTerm : orPred.children[i]];
    }
}

- (void) genOrTerm : (PKRuleNode *) orTerm {
    
    NSAssert (orTerm.children.count == 2,@"");
    
    [self->sql appendString : @" or"];
    
    [self genAndPred : orTerm.children[1]];
}

- (void) genAndPred : (PKRuleNode *) andPred {
    
    NSAssert (andPred.children.count >= 1,@"");
    
    [self genBasePred : andPred.children[0]];
    
    for (int i = 1; i < andPred.children.count; i++) {
        
        [self genAndTerm : andPred.children[i]];
    }
}

- (void) genAndTerm : (PKRuleNode *) andTerm {
    
    NSAssert (andTerm.children.count == 2,@"");
    
    [self->sql appendString : @" and"];
    
    [self genBasePred : andTerm.children[1]];
}


- (void) genBasePred : (PKRuleNode *) basePred {
    
    NSAssert (basePred.children.count == 1,@"");
    
    PKRuleNode * node = basePred.children[0];
    
    if ([node.name isEqualToString:@"primaryPred"]) {
        
        [self genPrimaryPred : node];
        
    } else if ([node.name isEqualToString:@"parenPred"]) {
        
        [self genParenPred : node];
    }
}

- (void) genParenPred : (PKRuleNode *) parenPred {
    
    NSAssert (parenPred.children.count == 3,@"");
    
    [self->sql appendString:@" ("];
    
    [self genPredicate : parenPred.children[1]];
    
    [self->sql appendString:@" )"];
}

- (void) genPrimaryPred : (PKRuleNode *) primaryPred {
    
    NSAssert (primaryPred.children.count == 1,@"");
    
    PKRuleNode * node = primaryPred.children[0];
    
    if ([node.name isEqualToString:@"simplePred"]) {
        
        [self genSimplePred : node];
        
    } else if ([node.name isEqualToString:@"negatedPred"]) {
        
        [self genNegatedPred : node];
    }
}

- (void) genNegatedPred : (PKRuleNode *) negatedPred {
    
    NSAssert (negatedPred.children.count == 2,@"");
    
    [self->sql appendString:@" not"];
    
    [self genSimplePred : negatedPred.children[1]];
}
//
// Simple predicates
//

- (void) genSimplePred : (PKRuleNode *) simplePred {
    
    NSAssert (simplePred.children.count == 1,@"");
    
    PKRuleNode * node = simplePred.children[0];
    
    if ([node.name isEqualToString:@"boolPred"]) {
        
        [self genBoolPred : node];
        
    } else if ([node.name isEqualToString:@"aggPred"]) {
        
        [self genAggPred : node];
        
    } else if ([node.name isEqualToString:@"basicPred"]) {
        
        [self genBasicPred : node];
    }
}
//
// Basic predicates
//
- (void) genBasicPred : (PKRuleNode *) basicPred {
    
    NSAssert (basicPred.children.count == 2,@"");
    
    [self genIdentifier : basicPred.children[0]];
    
    PKRuleNode * node = basicPred.children[1];
    
    if ([node.name isEqualToString:@"relTerm"]) {
        
        [self genRelTerm : node];
        
    } else if ([node.name isEqualToString:@"betweenTerm"]) {
        
        [self genBetweenTerm : node];
        
    } else if ([node.name isEqualToString:@"stringTerm"]) {
        
        [self genStringTerm : node];
        
    } else if ([node.name isEqualToString:@"inTerm"]) {
        
        [self genInTerm : node];
    }
}

- (void) genRelTerm : (PKRuleNode *) relTerm {
    
    NSAssert (relTerm.children.count == 2,@"");
    
    [self genRelOp : relTerm.children[0]];
    
    [self genValue : relTerm.children[1]];
}

- (void) genRelOp : (PKRuleNode *) relOp {
    
    NSAssert (relOp.children.count == 1,@"");

    PKRuleNode * node = relOp.children[0];
    
    NSString * op;
    
    if ([node.name isEqualToString:@"lt"]) {
    
        op = @" <";
        
    } else if ([node.name isEqualToString:@"le"]) {
        
        op = @" <=";
        
    } else if ([node.name isEqualToString:@"eq"]) {
        
        op = @" =";
        
    } else if ([node.name isEqualToString:@"ge"]) {
        
        op = @" >=";
        
    } else if ([node.name isEqualToString:@"gt"]) {
        
        op = @" >";
        
    } else if ([node.name isEqualToString:@"ne"]) {
        
        op = @" !=";
    }

    [self->sql appendString : op];
}

- (void) genBetweenTerm : (PKRuleNode *) betweenTerm {
    
    NSAssert (betweenTerm.children.count == 7 || betweenTerm.children.count == 6,@"");
    
    int index = 0;
    
    if (betweenTerm.children.count == 7) {
        
        [self->sql appendString:@" not"];
        
        index++;
    }
    
    [self->sql appendString:@" between"];
    
    [self genValue : betweenTerm.children[index + 2]];
    
    [self->sql appendString:@" and"];
    
    [self genValue : betweenTerm.children[index + 4]];
}

- (void) genInTerm : (PKRuleNode *) inTerm {
    
    NSAssert (inTerm.children.count == 3 || inTerm.children.count == 2,@"");
    
    int index = 0;
    
    if (inTerm.children.count == 3) {
        
        [self->sql appendString:@" not"];
        
        index++;
    }
    
    [self->sql appendString:@" in"];
    
    [self genArray : inTerm.children [index + 1]];
}
//
// String predicates
//
- (void) genStringTerm : (PKRuleNode *) stringTerm {
    
    NSAssert (stringTerm.children.count == 2,@"");
    
    PKRuleNode * node = stringTerm.children[0];
    
    NSAssert (node.children.count == 1,@"");
    
    node = node.children[0];
    
    NSString * string = [self stringWithoutQuotes:stringTerm.children[1]];
    
    if ([node.name isEqualToString:@"bw"]) {
        
        string = [NSString stringWithFormat:@"'%@%%'",string];
        
    } else if ([node.name isEqualToString:@"co"]) {
        
        string = [NSString stringWithFormat:@"'%%%@%%'",string];
        
    } else if ([node.name isEqualToString:@"ew"]) {
        
        string = [NSString stringWithFormat:@"'%%%@'",string];
        
    } else if ([node.name isEqualToString:@"lk"]) {
        
        string = [NSString stringWithFormat:@"'%@'",string];
        
        string = [string stringByReplacingOccurrencesOfString : @"*" withString : @"%"];

        string = [string stringByReplacingOccurrencesOfString : @"?" withString : @"_"];
    }
    
    [self->sql appendFormat:@" like %@",string];
}
//
// Boolean predicates
//
- (void) genBoolPred : (PKRuleNode *) boolPred {
    
    NSAssert (boolPred.children.count == 1,@"");
    
    PKRuleNode * node = boolPred.children[0];
    
    if ([node.name isEqualToString:@"truePred"]) {
        
        [self->sql appendString:@" true"];
        
    } else if ([node.name isEqualToString:@"falsePred"]) {
        
        [self->sql appendString : @" false"];
    }
}
//
// Aggregate predicates
//
- (void) genAggPred : (PKRuleNode *) aggPred {
    
    NSAssert (aggPred.children.count == 3,@"");
    
    PKRuleNode * node = aggPred.children[0];
    
    NSAssert (node.children.count == 1,@"");
    
    node = node.children[0];
    
    if ([node.name isEqualToString:@"any"] || [node.name isEqualToString:@"some"]) {
        
        [self->sql appendString:@" any"];
        
    } else if ([node.name isEqualToString:@"all"]) {
        
        [self->sql appendString:@" all"];
        
    } else if ([node.name isEqualToString:@"none"]) {
        
        [self->sql appendString:@" none"];
    }
    
    [self genIdentifier : aggPred.children[1]];
    
    [self genRelTerm : aggPred.children[2]];
}
//
// Arrays
//
- (void) genArray : (PKRuleNode *) array {
    
    NSAssert (array.children.count == 3 || array.children.count == 2,@"");
    
    [self->sql appendString:@" ("];
    
    if (array.children.count == 3) [self genElementList : array.children[1]];
    
    [self->sql appendString:@" )"];
}

- (void) genElementList : (PKRuleNode *) elementList {
    
    NSAssert (elementList.children.count >= 1,@"");
    
    [self genValue : elementList.children[0]];
    
    for (int i = 1; i < elementList.children.count; i++) {
        
        PKRuleNode * commaValue = elementList.children[i];
        
        NSAssert (commaValue.children.count == 2,@"");
        
        [self->sql appendString : @" ,"];
        
        [self genValue : commaValue.children[1]];
    }
}
//
// Values
//
- (void) genValue : (PKRuleNode *) value {
    
    NSAssert (value.children.count == 1,@"");
    
    PKRuleNode * node = value.children[0];
    
    if ([node.name isEqualToString:@"boolean"]) {
        
        [self genBoolean : node];
        
    } else if ([node.name isEqualToString:@"identifier"]) {
        
        [self genIdentifier : node];
        
    } else if ([node.name isEqualToString:@"string"]) {
        
        [self genString : node];
        
    } else if ([node.name isEqualToString:@"number"]) {
        
        [self genNumber : node];
        
    } else if ([node.name isEqualToString:@"parenValue"]) {
        
        [self genParenValue : node];
    }
}

- (void) genBoolean : (PKRuleNode *) boolean {
    
    NSAssert (boolean.children.count == 1,@"");
    
    PKRuleNode * node = boolean.children[0];
    
    if ([node.name isEqualToString:@"trueLit"]) {
        
        [self->sql appendString:@" true"];
        
    } else if ([node.name isEqualToString:@"falseLit"]) {
        
        [self->sql appendString:@" false"];
    }
}

- (void) genParenValue : (PKRuleNode *) parenValue {
    
    NSAssert (parenValue.children.count == 3,@"");
    
    [self->sql appendString:@" ("];
    
    [self genValue : parenValue.children[1]];
    
    [self->sql appendString:@" )"];
}
//
// Tokens
//
- (void) genIdentifier : (PKRuleNode *) identifier {
    
    NSAssert (identifier.children.count == 1,@"");
    
    PKTokenNode * node = identifier.children[0];
    
    PKToken * token = node.token;
    
    [self->sql appendFormat:@" %@",token.stringValue];
}

- (void) genNumber : (PKRuleNode *) number {
    
    NSAssert (number.children.count == 1,@"");
    
    PKTokenNode * node = number.children[0];
    
    PKToken * token = node.token;
    
    [self->sql appendFormat:@" %@",token.stringValue];
}

- (void) genString : (PKRuleNode *) string {
    
    NSAssert (string.children.count == 1,@"");
    
    PKTokenNode * node = string.children[0];
    
    PKToken * token = node.token;
    
    NSString * value = token.stringValue;
    
    value = [value substringFromIndex : 1];
    
    value = [value substringToIndex:value.length - 1];
    
    [self->sql appendFormat : @" '%@'",value];
}
//
// Helper methods
//
- (NSString *) stringWithoutQuotes : (PKRuleNode *) string {
    
    NSAssert (string.children.count == 1,@"");
    
    PKTokenNode * node = string.children[0];
    
    PKToken * token = node.token;
    
    NSString * value = token.stringValue;
    
    value = [value substringFromIndex : 1];
    
    value = [value substringToIndex:value.length - 1];
    
    return value;
}

@end
