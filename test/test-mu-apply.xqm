xquery version "3.1";

(:~
 : Tests for μ:apply.
 :
 : In most tests μ:xml is used to convert the mu-document to XML. This makes
 : it much easier to read. So, strictly, this is not a unit-test any more.
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace μ = 'http://xokomola.com/xquery/origami/mu' 
    at '../mu.xqm'; 

declare %unit:test function test:attribute-handler-default() 
{
    unit:assert-equals(
        μ:xml(μ:apply(
            ['x', map { 
                'a': function($e) { 
                    μ:data($e)[1] + μ:data($e)[2] 
                } 
            }],
            (2,4)
        )),
        <x a="6"/>,
        'Default attribute handler: add two extra args from data'
    )    
};

declare %unit:test function test:attribute-handler-custom() 
{
    unit:assert-equals(
        μ:xml(μ:apply(
            ['x', map { 
                'a': [ function($e,$x,$y) { 
                    $x + $y 
                }, 2,4 ]
            }]
        )),
        <x a="6"/>,
        'Custom attribute handler: add two extra args'
    )
};

declare %unit:test function test:content-handler-default()
{  
    unit:assert-equals(
        μ:xml(
            μ:apply(
                ['ul', 
                    function($e) { 
                        for $i in 1 to μ:data($e) 
                        return ['li', concat('item ', $i)] 
                    }
                ],
                3
            )
        ),
        <ul>
            <li>item 1</li>
            <li>item 2</li>
            <li>item 3</li>
        </ul>,
        'Default content handler: build a list'
    )
};

declare %unit:test function test:content-handler-custom()
{  
    (: 
     : The custom handler provides the number of items to the handler
     : function.
     :)
    unit:assert-equals(
        μ:xml(
            μ:apply(
                ['ul', 
                    [ function($e,$x) { 
                        for $i in 1 to $x 
                        return ['li', concat('item ', $i)] 
                    }, 3 ]
                ]
            )
        ),
        <ul>
            <li>item 1</li>
            <li>item 2</li>
            <li>item 3</li>
        </ul>,
        'Custom content handler: build a list'
    ),
    
    (: 
     : Identical result but produced with literal element constructors 
     :)
    unit:assert-equals(
        μ:xml(
            μ:apply(
                ['ul', 
                    [ function($e,$x) { 
                        for $i in 1 to $x 
                        return element li { concat('item ', $i) } 
                    }, 3 ]
                ]
            )
        ),
        <ul>
            <li>item 1</li>
            <li>item 2</li>
            <li>item 3</li>
        </ul>,
        'Default content handler: build a list with literal result node
         constructors.'
    )
    
};

(:
 : The following few tests should all produce this table.
 :)
declare variable $test:table :=
    <table>
        <tr>
          <td>item 1,1</td>
          <td>item 1,2</td>
        </tr>
        <tr>
          <td>item 2,1</td>
          <td>item 2,2</td>
        </tr>
        <tr>
          <td>item 3,1</td>
          <td>item 3,2</td>
        </tr>
    </table>;

(:
 : Shows how a nested apply is used to push processing forward into
 : the content produced by a handler.
 :)
declare %unit:test function test:nested-apply-table()
{    
    unit:assert-equals(
        μ:xml(
            μ:apply(
                ['table',
                    function($e) {
                        for $i in trace(1 to μ:data($e)[1], 'rows: ')
                        return
                            ['tr', 
                                function($e) {
                                    for $j in 1 to trace(μ:data($e)[2], 'cols: ')
                                    return
                                        ['td', concat('item ',$i,',',$j)]
                                }
                            ]
                    }
                ], 
                (3,2)
            )
        ),
        $test:table,
        'Use nested default handlers to produce a table'
    )
};
