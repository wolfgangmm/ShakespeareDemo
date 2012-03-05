xquery version "3.0";

module namespace app="http://exist-db.org/xquery/app";

import module namespace templates="http://exist-db.org/xquery/templates" at "templates.xql";
import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace tei2="http://exist-db.org/xquery/app/tei2html" at "tei2html.xql";
import module namespace kwic="http://exist-db.org/xquery/kwic"
    at "resource:org/exist/xquery/lib/kwic.xql";
    
declare namespace tei="http://www.tei-c.org/ns/1.0";

(:~
 : List Shakespeare works
 :)
declare function app:list-works($node as node(), $params as element(parameters)?, $model as item()*) {
    element { node-name($node) } {
        for $work in collection($config:data)/tei:TEI
        order by app:work-title($work)
        return
            templates:process($node/node(), $work)
    }
};

declare function app:work($node as node(), $params as element(parameters)?, $model as item()*) {
    let $id := request:get-parameter("id", ())
    let $work := collection($config:data)//id($id)
    return
        element { node-name($node) } {
            $node/@*,
            templates:process($node/node(), $work)
        }
};

declare function app:header($node as node(), $params as element(parameters)?, $model as item()*) {
    tei2:tei2html($model/tei:teiHeader)
};

declare function app:outline($node as node(), $params as element(parameters)?, $model as item()*) {
    let $details := $params/param[@name = "details"]/@value = "yes"
    let $work := $model/ancestor-or-self::tei:TEI
    let $current := $model
    return
        <ul>{
            for $act at $act-count in $work/tei:text/tei:body/tei:div
            return
                <li>{$act/tei:head/text()}
                    <ul>{
                        for $scene in $act/tei:div
                        let $class := if ($scene is $current) then "active" else ""
                        return
                            <li>
                                {
                                    if ($details) then (
                                        <p><a href="plays/{$scene/@xml:id}.html" class="{$class}">{$scene/tei:head/text()}</a></p>,
                                        <p>{$scene/tei:stage[1]/text()}</p>,
                                        <p><em>Speakers: </em>
                                        {
                                            string-join(
                                                for $speaker in distinct-values($scene//tei:speaker)
                                                order by $speaker
                                                return
                                                    $speaker,
                                                ", "
                                            )
                                        }
                                        </p>
                                    ) else
                                        <a href="plays/{$scene/@xml:id}.html" class="{$class}">{$scene/tei:head/text()}</a>
                                }
                            </li>
                    }</ul>
                </li>
        }</ul>
};

(:~
 : 
 :)
declare function app:work-title($node as node(), $params as element(parameters)?, $model as item()*) {
    let $type := $params/param[@name = "type"]/@value
    let $suffix := if ($type) then "." || $type else ()
    let $work := $model/ancestor-or-self::tei:TEI
    return
        <a href="{$node/@href}{$work/@xml:id}{$suffix}">{ app:work-title($work) }</a>
};

declare function app:work-title($work as element(tei:TEI)) {
    $work/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title/text()
};

declare function app:work-id($node as node(), $params as element(parameters)?, $model as item()*) {
    $model/@xml:id/string()
};

declare function app:epub-link($node as node(), $params as element(parameters)?, $model as item()*) {
    let $id := $model/@xml:id/string()
    return
        <a href="{$node/@href}{$id}.epub">{ $node/node() }</a>
};

declare function app:navigation($node as node(), $params as element(parameters)?, $div as item()*) {
    let $prevDiv := $div/preceding::tei:div[parent::tei:div][1]
    let $nextDiv := $div/following::tei:div[parent::tei:div][1]
    let $work := $div/ancestor-or-self::tei:TEI
    return
        element { node-name($node) } {
            $node/@*,
            if ($nextDiv) then
                <a href="plays/{$nextDiv/@xml:id}.html" class="next">Next Scene</a>
            else
                (),
            if ($prevDiv) then
                <a href="plays/{$prevDiv/@xml:id}.html" class="previous">Previous Scene</a>
            else
                (),
            <h5><a href="plays/{$work/@xml:id}">{app:work-title($work)}</a></h5>
        }
};

declare function app:view($node as node(), $params as element(parameters)?, $model as item()*) {
    let $id := request:get-parameter("id", ())
    for $div in $model/id($id)
    return
        <div class="play">
        { tei2:tei2html($div) }
        </div>
};

(:~
    Execute the query. The search results are not output immediately. Instead they
    are passed to nested templates through the $model parameter.
:)
declare function app:query($node as node()*, $params as element(parameters)?, $model as item()*) {
    session:create(),
    let $query := app:create-query()
    let $hits :=
        for $hit in collection($config:app-root)//tei:sp[ft:query(., $query)]
        order by ft:score($hit) descending
        return $hit
    let $store := session:set-attribute("apps.shakespeare", $hits)
    return
        (: Process nested templates :)
        <div>{ templates:process($node/*, $hits) }</div>
};

(:~
    Helper function: create a lucene query from the user input
:)
declare function app:create-query() {
    let $queryStr := request:get-parameter("query", ())
    let $mode := request:get-parameter("mode", "all")
    return
        <query>
        {
            if ($mode eq 'any') then
                for $term in tokenize($queryStr, '\s')
                return
                    <term occur="should">{$term}</term>
            else if ($mode eq 'all') then
                for $term in tokenize($queryStr, '\s')
                return
                    <term occur="must">{$term}</term>
            else if ($mode eq 'phrase') then
                <phrase>{$queryStr}</phrase>
            else
                <near>{$queryStr}</near>
        }
        </query>
};

(:~
    Read the last query result from the HTTP session and pass it to nested templates
    in the $model parameter.
:)
declare function app:from-session($node as node()*, $params as element(parameters)?, $model as item()*) {
    let $hits := session:get-attribute("apps.shakespeare")
    return
        templates:process($node/*, $hits)
};

(:~
    Create a span with the number of items in the current search result.
:)
declare function app:hit-count($node as node()*, $params as element(parameters)?, $model as item()*) {
    <span id="hit-count">{ count($model) }</span>
};

(:~
    Output the actual search result as a div, using the kwic module to summarize full text matches.
:)
declare function app:show-hits($node as node()*, $params as element(parameters)?, $model as item()*) {
    let $start := number(request:get-parameter("start", 1))
    for $hit at $p in subsequence($model, $start, 10)
    let $id := $hit/ancestor-or-self::tei:div[1]/@xml:id
    let $kwic := kwic:summarize($hit, <config width="40" table="yes" link="plays/{$id}.html"/>, util:function(xs:QName("app:filter"), 2))
    return
        <div class="hit">
            <span class="number">{$start + $p - 1}</span>
            <div>
                <p>From: <a href="plays/{$hit/ancestor::tei:TEI/@xml:id}.html">{app:work-title($hit/ancestor::tei:TEI)}</a>,
                <a href="plays/{$hit/ancestor::tei:div[1]/@xml:id}.html">{$hit/ancestor::tei:div[1]/tei:head/text()}</a></p>
                <table>{ $kwic }</table>
            </div>
        </div>
};

(:~
    Callback function called from the kwic module.
:)
declare function app:filter($node as node(), $mode as xs:string) as xs:string? {
  if ($node/parent::tei:speaker or $node/parent::tei:stage or $node/parent::tei:head) then 
      ()
  else if ($mode eq 'before') then 
      concat($node, ' ')
  else 
      concat(' ', $node)
};