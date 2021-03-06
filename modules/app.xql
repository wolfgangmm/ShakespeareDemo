xquery version "3.0";

module namespace app="http://exist-db.org/apps/";

import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace config="http://exist-db.org/apps/shakes/config" at "config.xqm";
import module namespace tei2="http://exist-db.org/xquery/app/tei2html" at "tei2html.xql";
import module namespace kwic="http://exist-db.org/xquery/kwic" at "resource:org/exist/xquery/lib/kwic.xql";
    
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace functx = "http://www.functx.com";

declare function functx:contains-any-of
  ( $arg as xs:string? ,
    $searchStrings as xs:string* )  as xs:boolean {

   some $searchString in $searchStrings
   satisfies contains($arg,$searchString)
 } ;

(:modified by applying functx:escape-for-regex() :)
declare function functx:number-of-matches 
  ( $arg as xs:string? ,
    $pattern as xs:string )  as xs:integer {

   count(tokenize(functx:escape-for-regex($arg),functx:escape-for-regex($pattern))) - 1
 } ;

declare function functx:escape-for-regex
  ( $arg as xs:string? )  as xs:string {

   replace($arg,
           '(\.|\[|\]|\\|\||\-|\^|\$|\?|\*|\+|\{|\}|\(|\))','\\$1')
 } ;

(:~
 : List Shakespeare works
 :)
declare 
    %templates:wrap
function app:list-works($node as node(), $model as map(*)) {
    map {
        "works" :=
            for $work in collection($config:data)/tei:TEI
            order by app:work-title($work)
            return
                $work
    }
};

declare
    %templates:wrap
function app:work($node as node(), $model as map(*), $id as xs:string?) {
    let $work := collection($config:data)//id($id)
    return
        map { "work" := $work }
};

declare function app:header($node as node(), $model as map(*)) {
    tei2:tei2html($model("work")/tei:teiHeader)
};

declare function app:outline($node as node(), $model as map(*), $details as xs:string) {
    let $details := $details = "yes"
    let $work := $model("work")/ancestor-or-self::tei:TEI
    let $current := $model("work")
    return
        (:If the work is a play:)
        if ($work//tei:speaker)
        then
            <ul xmlns="http://www.w3.org/1999/xhtml">
            {
                for $act in $work/tei:text/tei:body/tei:div
                return
                    <li>{$act/tei:head/text()}
                        <ul>{
                            for $scene in $act/tei:div
                            let $class := if ($scene is $current) then "active" else ""
                            return
                                <li>
                                    {
                                        if ($details) then (
                                            <p><a href="{$scene/@xml:id}.html" class="{$class}">{$scene/tei:head/text()}</a></p>,
                                            <p>{$scene/tei:stage[1]/text()}</p>,
                                            
                                            if ($scene//tei:speaker)
                                            then
                                                <p><em>Speakers: </em>
                                                {
                                                    string-join(
                                                        for $speaker in distinct-values($scene//tei:speaker)
                                                        order by $speaker
                                                        return
                                                            $speaker
                                                    , ", ")
                                                }
                                                </p>
                                            else ()
                                        ) else
                                            <a href="{$scene/@xml:id}.html" class="{$class}">{$scene/tei:head/text()}</a>
                                    }
                                </li>
                        }</ul>
                    </li>
            }</ul>
        else
            (:If the work is Lover's Complaint, Phoenix and Turtle:)
            if ($work/tei:text/tei:body/tei:div/tei:lg/tei:l)
            then
                <table class="poem-list" xmlns="http://www.w3.org/1999/xhtml">
                {
                    for $stanza at $stanza-count in $work/tei:text/tei:body/tei:div/tei:lg
                    let $class := if ($stanza is $current) then "active" else ""
                    return
                        <tr>
                            <td><a href="{$stanza/@xml:id}.html" class="{$class}">Stanza {$stanza-count}</a></td> 
                            <td class="first-line">
                            {
                                if ($stanza/tei:lg/tei:l)
                                then $stanza/tei:lg[1]/tei:l[1]/text()
                                else
                                    if ($stanza/tei:l)
                                    then $stanza/tei:l[1]/text()
                                    else ''
                            }
                            </td>
                        </tr>
                }
                </table>
            else
                (:If the work is Rape of Lucrece, Venus and Adonis:) 
                if ($work/tei:text/tei:body/tei:div/tei:lg/tei:lg/tei:l)
                then
                    <table class="poem-list" xmlns="http://www.w3.org/1999/xhtml">
                    {
                        for $stanza in $work/tei:text/tei:body/tei:div/tei:lg
                        let $class := if ($stanza is $current) then "active" else ""
                        return
                            <tr>
                                <td><a href="{$stanza/@xml:id}.html" class="{$class}">Stanza {$stanza/@n/string()}</a></td> 
                                <td class="first-line">
                                {
                                    if ($stanza/tei:lg/tei:l)
                                    then $stanza/tei:lg[1]/tei:l[1]/text()
                                    else
                                        if ($stanza/tei:l)
                                        then $stanza/tei:l[1]/text()
                                        else 'WHAT?'
                                }
                                </td>
                            </tr>
                    }
                    </table>
                else
                    (:If the work is Sonnets.:)
                    <table class="poem-list" xmlns="http://www.w3.org/1999/xhtml">
                    {
                        for $sonnet in $work/tei:text/tei:body/tei:div/tei:div
                        let $class := if ($sonnet is $current) then "active" else ""
                        return
                            <tr>
                                <td><a href="{$sonnet/@xml:id}.html" class="{$class}">{$sonnet/tei:head/string()}</a></td> 
                                <td class="first-line">
                                {
                                    if ($sonnet/tei:lg/tei:l)
                                    then $sonnet/tei:lg[1]/tei:l[1]/text()
                                    else
                                        if ($sonnet/tei:l)
                                        then $sonnet/tei:l[1]/text()
                                        else 'WHAT?'
                                }
                                </td>
                            </tr>
                    }
                    </table>
};

(:~
 : 
 :)
declare function app:work-title($node as node(), $model as map(*), $type as xs:string?) {
    let $suffix := if ($type) then "." || $type else ()
    let $work := $model("work")/ancestor-or-self::tei:TEI
    return
        <a xmlns="http://www.w3.org/1999/xhtml" href="{$node/@href}{$work/@xml:id}{$suffix}">{ app:work-title($work) }</a>
};

declare %private function app:work-title($work as element(tei:TEI)) {
    $work/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[1]/text()
};

declare 
    %templates:wrap
function app:checkbox($node as node(), $model as map(*), $target-texts as xs:string*) {
    attribute { "value" } {
        $model("work")/@xml:id/string()
    },
    if ($model("work")/@xml:id/string() = $target-texts) then
        attribute checked { "checked" }
    else
        ()
};

declare function app:work-type($node as node(), $model as map(*)) {
    let $work := $model("work")/ancestor-or-self::tei:TEI
    let $id := $work/@xml:id/string()
    let $work-types := doc(concat($config:data-root, '/', 'work-types.xml'))//item[id = $id]/value
    return 
        string-join(
            for $work-type in $work-types
            order by $work-type 
            return $work-type
        , ', ')    
};

declare function app:epub-link($node as node(), $model as map(*)) {
    let $id := $model("work")/@xml:id/string()
    return
        <a xmlns="http://www.w3.org/1999/xhtml" href="{$node/@href}{$id}.epub">{ $node/node() }</a>
};

declare function app:pdf-link($node as node(), $model as map(*)) {
    let $id := $model("work")/@xml:id/string()
    return
        <a xmlns="http://www.w3.org/1999/xhtml" href="{$node/@href}{$id}.pdf">{ $node/node() }</a>
};

declare function app:xml-link($node as node(), $model as map(*)) {
    let $doc-path := document-uri(root($model("work")))
    let $eXide-link := templates:link-to-app("http://exist-db.org/apps/eXide", "index.html?open=" || $doc-path)
    let $rest-link := '/exist/rest' || $doc-path
    return
        if (xmldb:collection-available('/db/apps/eXide'))
        then <a xmlns="http://www.w3.org/1999/xhtml" href="{$eXide-link}" target="_blank">{ $node/node() }</a>
        else <a xmlns="http://www.w3.org/1999/xhtml" href="{$rest-link}" target="_blank">{ $node/node() }</a>
};

declare function app:copy-params($node as node(), $model as map(*)) {
    element { node-name($node) } {
        $node/@* except $node/@href,
        attribute href {
            let $link := $node/@href
            let $params :=
                string-join(
                    for $param in request:get-parameter-names()
                    for $value in request:get-parameter($param, ())
                    return
                        $param || "=" || $value,
                    "&amp;"
                )
            return
                $link || "?" || $params
        },
        $node/node()
    }
};

declare function app:work-types($node as node(), $model as map(*)) {
    let $types := distinct-values(doc(concat($config:data-root, '/', 'work-types.xml'))//value)
    let $control :=
        <select multiple="multiple" name="work-types" class="form-control">
            <option value="all">All Work Types</option>
            {for $type in $types
            return <option value="{$type}">{$type}</option>
            }
        </select>
    return
        templates:form-control($control, $model)
};

declare function app:navigation($node as node(), $model as map(*)) {
    let $div := $model("work")
    let $prevDiv := $div/preceding::tei:div[parent::tei:div][1]
    let $nextDiv := $div/following::tei:div[parent::tei:div][1]
    let $work := $div/ancestor-or-self::tei:TEI
    return
        element { node-name($node) } {
            $node/@*,
            if ($prevDiv) then
                <a xmlns="http://www.w3.org/1999/xhtml" href="{$prevDiv/@xml:id}.html" class="previous">
                    <i class="glyphicon glyphicon-chevron-left"/> Previous Scene</a>
            else
                (),
            if ($nextDiv) then
                <a xmlns="http://www.w3.org/1999/xhtml" href="{$nextDiv/@xml:id}.html" class="next">
                    Next Scene <i class="glyphicon glyphicon-chevron-right"/></a>
            else
                (),
            <h5 xmlns="http://www.w3.org/1999/xhtml"><a href="{$work/@xml:id}">{app:work-title($work)}</a></h5>
        }
};

declare 
    %templates:default("action", "browse")
function app:view-div($node as node(), $model as map(*), $id as xs:string, $action as xs:string) {
    let $query := 
        if ($action eq 'search')
        then session:get-attribute("apps.shakespeare.query")
        else ()
    let $scope := 
        if ($query) 
        then session:get-attribute("apps.shakespeare.scope") 
        else ()
    let $div :=$model("work")/id($id)
    let $div :=
        if ($query) then
            if ($scope eq 'narrow') then
                util:expand(($div[.//tei:sp[ft:query(., $query)]], $div[.//tei:lg[ft:query(., $query)]]), "add-exist-id=all")
            else
                util:expand($div[ft:query(., $query)], "add-exist-id=all")
        else
            $div
    return
        <div xmlns="http://www.w3.org/1999/xhtml" class="play">
        { tei2:tei2html($div) }
        </div>
};

(:~
    Execute the query. The search results are not output immediately. Instead they
    are passed to nested templates through the $model parameter.
:)
declare 
    %templates:default("mode", "any")
    %templates:default("scope", "narrow")
    %templates:default("work-types", "all")
    %templates:default("target-texts", "all")
function app:query($node as node()*, $model as map(*), $query as xs:string?, $mode as xs:string, $scope as xs:string, 
    $work-types as xs:string+, $target-texts as xs:string+) {
    let $queryExpr := app:create-query($query, $mode)
    return
        if (empty($queryExpr) or $queryExpr = "") then
            let $cached := session:get-attribute("apps.shakespeare")
            return
                map {
                    "hits" := $cached,
                    "query" := session:get-attribute("apps.shakespeare.query"),
                    "scope" := $scope
                }
        else
            (:Get the work ids of the work types selected.:)  
            let $target-text-ids := distinct-values(doc(concat($config:data-root, '/', 'work-types.xml'))//item[value = $work-types]/id)
            (:If no individual works have been selected, search in the works with ids selected by type;
            if indiidual works have been selected, then neglect that no selection has been done in works according to type.:) 
            let $target-texts := 
                if ($target-texts = 'all' and $work-types = 'all')
                then 'all' 
                else 
                    if ($target-texts = 'all')
                    then $target-text-ids
                    else 
                        if ($work-types = "all") then $target-texts else ($target-texts[. = $target-text-ids])
            let $context := 
                if ($target-texts = 'all')
                then collection($config:data-root)/tei:TEI
                else collection($config:data-root)//tei:TEI[@xml:id = $target-texts]
            let $hits :=
                if ($scope eq 'narrow')
                then
                    for $hit in ($context//tei:sp[ft:query(., $queryExpr)], $context//tei:lg[ft:query(., $queryExpr)])
                    order by ft:score($hit) descending
                    return $hit
                else
                    for $hit in $context//tei:div[not(tei:div)][ft:query(., $queryExpr)]
                    order by ft:score($hit) descending
                    return $hit
            let $store := (
                session:set-attribute("apps.shakespeare", $hits),
                session:set-attribute("apps.shakespeare.query", $queryExpr),
                session:set-attribute("apps.shakespeare.scope", $scope)
            )
            return
                (: Process nested templates :)
                map {
                    "hits" := $hits,
                    "query" := $queryExpr
                }
};

(:~
    Helper function: create a lucene query from the user input
:)
declare %private function app:create-query($query-string as xs:string?, $mode as xs:string) {
    let $query-string := 
        if ($query-string) 
        then app:sanitize-lucene-query($query-string) 
        else ''
    let $query-string := normalize-space($query-string)
    let $query:=
        (:If the query contains any operator used in sandard lucene searches or regex searches, pass it on to the query parser;:) 
        if (functx:contains-any-of($query-string, ('AND', 'OR', 'NOT', '+', '-', '!', '~', '^', '.', '?', '*', '|', '{','[', '(', '<', '@', '#', '&amp;')) and $mode eq 'any')
        then 
            let $luceneParse := app:parse-lucene($query-string)
            let $luceneXML := util:parse($luceneParse)
            let $lucene2xml := app:lucene2xml($luceneXML/node(), $mode)
            return $lucene2xml
        (:otherwise the query is performed by selecting one of the special options (any, all, phrase, near, fuzzy, wildcard or regex):)
        else
            let $query-string := tokenize($query-string, '\s')
            let $last-item := $query-string[last()]
            let $query-string := 
                if ($last-item castable as xs:integer) 
                then string-join(subsequence($query-string, 1, count($query-string) - 1), ' ') 
                else string-join($query-string, ' ')
            let $query :=
                <query>
                    {
                        if ($mode eq 'any') 
                        then
                            for $term in tokenize($query-string, '\s')
                            return <term occur="should">{$term}</term>
                        else if ($mode eq 'all') 
                        then
                            <bool>
                            {
                                for $term in tokenize($query-string, '\s')
                                return <term occur="must">{$term}</term>
                            }
                            </bool>
                        else 
                            if ($mode eq 'phrase') 
                            then <phrase>{$query-string}</phrase>
                            else
                                if ($mode eq 'near-unordered')
                                then <near slop="{if ($last-item castable as xs:integer) then $last-item else 5}" ordered="no">{$query-string}</near>
                                else 
                                    if ($mode eq 'near-ordered')
                                    then <near slop="{if ($last-item castable as xs:integer) then $last-item else 5}" ordered="yes">{$query-string}</near>
                                    else 
                                        if ($mode eq 'fuzzy')
                                        then <fuzzy max-edits="{if ($last-item castable as xs:integer and number($last-item) < 3) then $last-item else 2}">{$query-string}</fuzzy>
                                        else 
                                            if ($mode eq 'wildcard')
                                            then <wildcard>{$query-string}</wildcard>
                                            else 
                                                if ($mode eq 'regex')
                                                then <regex>{$query-string}</regex>
                                                else ()
                    }</query>
            return $query
    return $query
    
};

(:~
 : Create a bootstrap pagination element to navigate through the hits.
 :)
declare
    %templates:wrap
    %templates:default('start', 1)
    %templates:default("per-page", 10)
    %templates:default("min-hits", 0)
    %templates:default("max-pages", 10)
function app:paginate($node as node(), $model as map(*), $start as xs:int, $per-page as xs:int, $min-hits as xs:int,
    $max-pages as xs:int) {
    if ($min-hits < 0 or count($model("hits")) >= $min-hits) then
        let $count := xs:integer(ceiling(count($model("hits"))) div $per-page) + 1
        let $middle := ($max-pages + 1) idiv 2
        return (
            if ($start = 1) then (
                <li class="disabled">
                    <a><i class="glyphicon glyphicon-fast-backward"/></a>
                </li>,
                <li class="disabled">
                    <a><i class="glyphicon glyphicon-backward"/></a>
                </li>
            ) else (
                <li>
                    <a href="?start=1"><i class="glyphicon glyphicon-fast-backward"/></a>
                </li>,
                <li>
                    <a href="?start={max( ($start - $per-page, 1 ) ) }"><i class="glyphicon glyphicon-backward"/></a>
                </li>
            ),
            let $startPage := xs:integer(ceiling($start div $per-page))
            let $lowerBound := max(($startPage - ($max-pages idiv 2), 1))
            let $upperBound := min(($lowerBound + $max-pages - 1, $count))
            let $lowerBound := max(($upperBound - $max-pages + 1, 1))
            for $i in $lowerBound to $upperBound
            return
                if ($i = ceiling($start div $per-page)) then
                    <li class="active"><a href="?start={max( (($i - 1) * $per-page + 1, 1) )}">{$i}</a></li>
                else
                    <li><a href="?start={max( (($i - 1) * $per-page + 1, 1)) }">{$i}</a></li>,
            if ($start + $per-page < count($model("hits"))) then (
                <li>
                    <a href="?start={$start + $per-page}"><i class="glyphicon glyphicon-forward"/></a>
                </li>,
                <li>
                    <a href="?start={max( (($count - 1) * $per-page + 1, 1))}"><i class="glyphicon glyphicon-fast-forward"/></a>
                </li>
            ) else (
                <li class="disabled">
                    <a><i class="glyphicon glyphicon-forward"/></a>
                </li>,
                <li>
                    <a><i class="glyphicon glyphicon-fast-forward"/></a>
                </li>
            )
        ) else
            ()
};

(:~
    Create a span with the number of items in the current search result.
:)
declare function app:hit-count($node as node()*, $model as map(*)) {
    <span xmlns="http://www.w3.org/1999/xhtml" id="hit-count">{ count($model("hits")) }</span>
};

(:~
    Output the actual search result as a div, using the kwic module to summarize full text matches.
:)
declare 
    %templates:wrap
    %templates:default("start", 1)
    %templates:default("per-page", 10)
function app:show-hits($node as node()*, $model as map(*), $start as xs:integer, $per-page as xs:integer) {
    for $hit at $p in subsequence($model("hits"), $start, $per-page)
    let $div := $hit/ancestor-or-self::tei:div[1]
    let $div-id := $div/@xml:id/string()
    let $div-head := $div/tei:head/text() 
    let $work := $hit/ancestor::tei:TEI
    let $work-id := $work/@xml:id/string()
    let $work-title := app:work-title($work)
    (:pad hit with surrounding siblings:)
    let $hit-padded := <hit>{($hit/preceding-sibling::*[1], $hit, $hit/following-sibling::*[1])}</hit>
    let $loc := 
        <tr class="reference">
            <td colspan="3">
                <span class="number">{$start + $p - 1}</span>
                <a href="{$work-id}.html">{$work-title}</a>, <a href="{$div-id}.html?action=search">{$div-head}</a>
            </td>
        </tr>
    let $matchId := ($hit/@xml:id, util:node-id($hit))[1]
    let $config := <config width="120" table="yes" link="{$div-id}.html?action=search#{$matchId}"/>
    let $kwic := kwic:summarize($hit-padded, $config, app:filter#2)
    return
        ($loc, $kwic)        
};

(:~
    Callback function called from the kwic module.
:)
declare %private function app:filter($node as node(), $mode as xs:string) as xs:string? {
  if ($node/parent::tei:speaker or $node/parent::tei:stage or $node/parent::tei:head) then 
      concat('(', $node, ':) ')
  else if ($mode eq 'before') then 
      concat($node, ' ')
  else 
      concat(' ', $node)
};

declare function app:base($node as node(), $model as map(*)) {
    let $context := request:get-context-path()
    let $app-root := substring-after($config:app-root, "/db/")
    return
        <base xmlns="http://www.w3.org/1999/xhtml" href="{$context}/{$app-root}/"/>
};

(: This functions provides crude way to avoid the most common errors with paired expressions and apostrophes. :)
(: TODO: check order of pairs:)
declare %private function app:sanitize-lucene-query($query-string as xs:string) as xs:string {
    let $query-string := replace($query-string, "'", "''") (:escape apostrophes:)
    (:TODO: notify user if query has been modified.:)
    (:Remove colons – Lucene fields are not supported.:)
    let $query-string := translate($query-string, ":", " ")
    let $query-string := 
	   if (functx:number-of-matches($query-string, '"') mod 2) 
	   then $query-string
	   else replace($query-string, '"', ' ') (:if there is an uneven number of quotation marks, delete all quotation marks.:)
    let $query-string := 
	   if ((functx:number-of-matches($query-string, '\(') + functx:number-of-matches($query-string, '\)')) mod 2 eq 0) 
	   then $query-string
	   else translate($query-string, '()', ' ') (:if there is an uneven number of parentheses, delete all parentheses.:)
    let $query-string := 
	   if ((functx:number-of-matches($query-string, '\[') + functx:number-of-matches($query-string, '\]')) mod 2 eq 0) 
	   then $query-string
	   else translate($query-string, '[]', ' ') (:if there is an uneven number of brackets, delete all brackets.:)
    let $query-string := 
	   if ((functx:number-of-matches($query-string, '{') + functx:number-of-matches($query-string, '}')) mod 2 eq 0) 
	   then $query-string
	   else translate($query-string, '{}', ' ') (:if there is an uneven number of braces, delete all braces.:)
    let $query-string := 
	   if ((functx:number-of-matches($query-string, '<') + functx:number-of-matches($query-string, '>')) mod 2 eq 0) 
	   then $query-string
	   else translate($query-string, '<>', ' ') (:if there is an uneven number of angle brackets, delete all angle brackets.:)
    return $query-string
};

(: Function to translate a Lucene search string to an intermediate string mimicking the XML syntax, 
with some additions for later parsing of boolean operators. The resulting intermediary XML search string will be parsed as XML with util:parse(). 
Based on Ron Van den Branden, https://rvdb.wordpress.com/2010/08/04/exist-lucene-to-xml-syntax/:)
(:TODO:
The following cases are not covered:
1)
<query><near slop="10"><first end="4">snake</first><term>fillet</term></near></query>
as opposed to
<query><near slop="10"><first end="4">fillet</first><term>snake</term></near></query>

w(..)+d, w[uiaeo]+d is not treated correctly as regex.
:)
declare %private function app:parse-lucene($string as xs:string) {
    (: replace all symbolic booleans with lexical counterparts :)
    if (matches($string, '[^\\](\|{2}|&amp;{2}|!) ')) 
    then
        let $rep := 
            replace(
            replace(
            replace(
                $string, 
            '&amp;{2} ', 'AND '), 
            '\|{2} ', 'OR '), 
            '! ', 'NOT ')
        return app:parse-lucene($rep)                
    else 
        (: replace all booleans with '<AND/>|<OR/>|<NOT/>' :)
        if (matches($string, '[^<](AND|OR|NOT) ')) 
        then
            let $rep := replace($string, '(AND|OR|NOT) ', '<$1/>')
            return app:parse-lucene($rep)
        else 
            (: replace all '+' modifiers in token-initial position with '<AND/>' :)
            if (matches($string, '(^|[^\w&quot;])\+[\w&quot;(]'))
            then
                let $rep := replace($string, '(^|[^\w&quot;])\+([\w&quot;(])', '$1<AND type=_+_/>$2')
                return app:parse-lucene($rep)
            else 
                (: replace all '-' modifiers in token-initial position with '<NOT/>' :)
                if (matches($string, '(^|[^\w&quot;])-[\w&quot;(]'))
                then
                    let $rep := replace($string, '(^|[^\w&quot;])-([\w&quot;(])', '$1<NOT type=_-_/>$2')
                    return app:parse-lucene($rep)
                else 
                    (: replace parentheses with '<bool></bool>' :)
                    (:NB: regex also uses parentheses!:) 
                    if (matches($string, '(^|[\W-[\\]]|>)\(.*?[^\\]\)(\^(\d+))?(<|\W|$)'))                
                    then
                        let $rep := 
                            (: add @boost attribute when string ends in ^\d :)
                            (:if (matches($string, '(^|\W|>)\(.*?\)(\^(\d+))(<|\W|$)')) 
                            then replace($string, '(^|\W|>)\((.*?)\)(\^(\d+))(<|\W|$)', '$1<bool boost=_$4_>$2</bool>$5')
                            else:) replace($string, '(^|\W|>)\((.*?)\)(<|\W|$)', '$1<bool>$2</bool>$3')
                        return app:parse-lucene($rep)
                    else 
                        (: replace quoted phrases with '<near slop="0"></bool>' :)
                        if (matches($string, '(^|\W|>)(&quot;).*?\2([~^]\d+)?(<|\W|$)')) 
                        then
                            let $rep := 
                                (: add @boost attribute when phrase ends in ^\d :)
                                (:if (matches($string, '(^|\W|>)(&quot;).*?\2([\^]\d+)?(<|\W|$)')) 
                                then replace($string, '(^|\W|>)(&quot;)(.*?)\2([~^](\d+))?(<|\W|$)', '$1<near boost=_$5_>$3</near>$6')
                                (\: add @slop attribute in other cases :\)
                                else:) replace($string, '(^|\W|>)(&quot;)(.*?)\2([~^](\d+))?(<|\W|$)', '$1<near slop=_$5_>$3</near>$6')
                            return app:parse-lucene($rep)
                        else (: wrap fuzzy search strings in '<fuzzy max-edits=""></fuzzy>' :)
                            if (matches($string, '[\w-[<>]]+?~[\d.]*')) 
                            then
                                let $rep := replace($string, '([\w-[<>]]+?)~([\d.]*)', '<fuzzy max-edits=_$2_>$1</fuzzy>')
                                return app:parse-lucene($rep)
                            else (: wrap resulting string in '<query></query>' :)
                                concat('<query>', replace(normalize-space($string), '_', '"'), '</query>')
};

(: Function to transform the intermediary structures in the search query generated through app:parse-lucene() and util:parse() 
to full-fledged boolean expressions employing XML query syntax. 
Based on Ron Van den Branden, https://rvdb.wordpress.com/2010/08/04/exist-lucene-to-xml-syntax/:)
declare %private function app:lucene2xml($node as item(), $mode as xs:string) {
    typeswitch ($node)
        case element(query) return 
            element { node-name($node)} {
            element bool {
            $node/node()/app:lucene2xml(., $mode)
        }
    }
    case element(AND) return ()
    case element(OR) return ()
    case element(NOT) return ()
    case element() return
        let $name := 
            if (($node/self::phrase | $node/self::near)[not(@slop > 0)]) 
            then 'phrase' 
            else node-name($node)
        return
            element { $name } {
                $node/@*,
                    if (($node/following-sibling::*[1] | $node/preceding-sibling::*[1])[self::AND or self::OR or self::NOT or self::bool])
                    then
                        attribute occur {
                            if ($node/preceding-sibling::*[1][self::AND]) 
                            then 'must'
                            else 
                                if ($node/preceding-sibling::*[1][self::NOT]) 
                                then 'not'
                                else 
                                    if ($node[self::bool]and $node/following-sibling::*[1][self::AND])
                                    then 'must'
                                    else
                                        if ($node/following-sibling::*[1][self::AND or self::OR or self::NOT][not(@type)]) 
                                        then 'should' (:must?:) 
                                        else 'should'
                        }
                    else ()
                    ,
                    $node/node()/app:lucene2xml(., $mode)
        }
    case text() return
        if ($node/parent::*[self::query or self::bool]) 
        then
            for $tok at $p in tokenize($node, '\s+')[normalize-space()]
            (:Here the query switches into regex mode based on whether or not characters used in regex expressions are present in $tok.:)
            (:It is not possible reliably to distinguish reliably between a wildcard search and a regex search, so switching into wildcard searches is ruled out here.:)
            (:One could also simply dispense with 'term' and use 'regex' instead - is there a speed penalty?:)
                let $el-name := 
                    if (matches($tok, '((^|[^\\])[.?*+()\[\]\\^|{}#@&amp;<>~]|\$$)') or $mode eq 'regex')
                    then 'regex'
                    else 'term'
                return 
                    element { $el-name } {
                        attribute occur {
                        (:if the term follows AND:)
                        if ($p = 1 and $node/preceding-sibling::*[1][self::AND]) 
                        then 'must'
                        else 
                            (:if the term follows NOT:)
                            if ($p = 1 and $node/preceding-sibling::*[1][self::NOT])
                            then 'not'
                            else (:if the term is preceded by AND:)
                                if ($p = 1 and $node/following-sibling::*[1][self::AND][not(@type)])
                                then 'must'
                                    (:if the term follows OR and is preceded by OR or NOT, or if it is standing on its own:)
                                else 'should'
                    }
                    (:,
                    if (matches($tok, '((^|[^\\])[.?*+()\[\]\\^|{}#@&amp;<>~]|\$$)')) 
                    then
                        (\:regex searches have to be lower-cased:\)
                        attribute boost {
                            lower-case(replace($tok, '(.*?)(\^(\d+))(\W|$)', '$3'))
                        }
                    else ():)
        ,
        (:regex searches have to be lower-cased:)
        lower-case(normalize-space(replace($tok, '(.*?)(\^(\d+))(\W|$)', '$1')))
        }
        else normalize-space($node)
    default return
        $node
};
