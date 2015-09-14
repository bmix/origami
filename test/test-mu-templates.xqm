xquery version "3.1";

(:~
 : Origami tests: μ:template
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace μ = 'http://xokomola.com/xquery/origami/mu'
    at '../mu.xqm';

declare %unit:test function test:template-identity-function() 
{
    unit:assert-equals(
        μ:apply(μ:template(<p><x y="10"/></p>, ())),
        ['p', ['x', map { 'y': '10' }]],
        'Identity transform'
    ),
      
    unit:assert-equals(
        μ:apply(μ:template(
            <p><x y="10"/></p>, 
            ['*', μ:copy()]
        )),
        ['p', ['x', map { 'y': '10' }]],
        'Identity transform using copy node transformer'
    ),
        
    (: because p already copies this will never hit 'x' rule :)
    unit:assert-equals(
        μ:apply(μ:template(
            <doc><p><x y="10"/></p><y x="20"/></doc>, 
            (
                ['p', μ:copy()],
                ['x', μ:copy()],
                ['y', μ:copy()]
            )
        )),
        ['doc', ['p', ['x', map { 'y': '10' }]],['y', map { 'x': '20' }]],
        'Identity transform using multiple rules'
    ),
    
    unit:assert-equals(
        μ:apply(μ:template(
            ['doc', ['p', ['x', map { 'y': '10' }]],['p', ['y', map { 'x': '20' }]]], 
            ['*', function($n) { $n }]
        )),
        ['doc', ['p', ['x', map { 'y': '10' }]],['p', ['y', map { 'x': '20' }]]],
        'Identity transform using custom node transformer and with mu-doc as input'
    )
};

(:~
 : A context function will typecheck context arguments and return
 : the context that will be available in the template rules ($c).
 :)
declare %unit:test function test:template-context-function() 
{
    unit:assert-equals(
        μ:apply(μ:template(
            <p><x y="10"/></p>, 
            ['p', function($n,$c) { ['foo', $c] }]
        ), 12),
        ['foo', 12],
        "One argument template"
    ),
    
    unit:assert-equals(
        μ:apply(μ:template(
            <p><x y="10"/></p>, 
            ['p', function($n,$c) { <foo>{ $c }</foo> }]
        ), 12),
        <foo>12</foo>,
        "One argument template producing XML element node")
};
