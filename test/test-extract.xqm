xquery version "3.0";

(:~
 : Origami tests
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

declare %unit:test function test:extract-document-order() {
    unit:assert-equals(
        xf:extract(
            <bar>
                <p id="1"/>
                <p/>
                <foo>
                    <p id="2"/>
                    <p id="3"/>
                </foo>
                <bla>
                    <bar>
                        <p id="4"/>
                    </bar>
                </bla>
                <p id="5"/>
            </bar>,        
            xf:select('p[@id]')),
        (<p id="1"/>,<p id="2"/>,<p id="3"/>,<p id="4"/>,<p id="5"/>)
    ),
    unit:assert-equals(
        xf:extract(
            <bar>
                <p id="1"/>
                <p/>
                <foo>
                    <p id="2"/>
                    <p id="3"/>
                </foo>
                <bla>
                    <bar>
                        <p id="4"/>
                    </bar>
                </bla>
                <p id="5"/>
            </bar>,
            xf:select('.//p[@id]')),
        (<p id="1"/>,<p id="2"/>,<p id="3"/>,<p id="4"/>,<p id="5"/>)
    )    
};

declare %unit:test function test:extract-composed() {
    unit:assert-equals(
        xf:extract(xf:select((xf:select('ul'), xf:select('li'))))(
            <div>
                <li>item 1</li>
                <li>item 2</li>
                <ul>
                    <li>item 3</li>
                    <li>item 4</li>
                </ul>
                <li>item 5</li>
            </div>
        ),
        (<li>item 3</li>,<li>item 4</li>))
};
