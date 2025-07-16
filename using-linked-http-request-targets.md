# Generating Linked Data with YARRRML: using linked HTTP request targets

* [Before we start the tutorial](#before-we-start-the-tutorial)
  * [Learning objective](#learning-objective)
  * [Prerequisites](#prerequisites)
* [Concepts](#concepts)
  * [HTTP request targets](#http-request-targets)
* [Example](#example)
  * [Initial YARRRML document](#initial-yarrrml-document)
  * [Output locations](#output-locations)
* [What rules are needed](#what-rules-are-needed)
* [How to generate triples for Solid's authorization rules](#how-to-generate-triples-for-solids-authorization-rules)
* [How to output to linked web resources](#how-to-output-to-linked-web-resources)
* [Wrapping up](#wrapping-up)
* [More information](#more-information)

## Before we start the tutorial

### Learning objective

At the end of this tutorial,
you'll be able to manually write YARRRML rules
that output RDF to web resources that are linked to other web resources.

### Prerequisites

You need some knowledge about Solid pods:

* A Solid pod can be used to host web resources that are accessible via HTTP methods.
* Access to web resources can be specified using Solid's authorization Rules.
* These authorization rules need to be available as RDF in [Access Control List (ACL) resources](https://solidproject.org/TR/wac#acl-resources).
* ACL resources are linked to the web resource they apply to, as specified in [ACL Resource Discovery](https://solidproject.org/TR/wac#acl-resource-discovery).

Optionally, if you want to understand the mapping we use to define the authorization rules that will be written to the ACL resource in our example,
we suggest to read about Solid's [Authorization Rules](https://solidproject.org/TR/wac#authorization-rule).

## Concepts

### HTTP request targets

An HTTP request target is a target resulting in output going to web resources, using HTTP methods.
We distinguish two types of HTTP request targets:

* Direct HTTP request targets, which write to a web resource.
  We handled these in our using targets tutorial.
* Linked HTTP request targets, which write to a web resource that is linked to another web resource.
  We handle these here.

## Example

Consider the following columns from the CSV file [example-data/x-domain/lindner/tutorial_products.csv](example-data/x-domain/lindner/tutorial_products.csv):

|**Product_id**|**Product Name**|
|--------------|----------------|
|Nortec_1234|Nortec|
|tile_1234|Calcium sulfate panel|
|pedestal_1234|Pedestal|
|pedestal_glue_1234|Pedestal glue|
|Nortec_1235|Nortec acoustic|
|acoustic_layer_1235|Acoustic layer|

They contain information about six different products, corresponding with the six rows.
The information includes an id and a, product name.

Also, consider the CSV file [example-data/x-domain/lindner/tutorial_products_acl.csv](example-data/x-domain/lindner/tutorial_products_acl.csv).
It contains input for writing Solid's [authorization rules](https://solidproject.org/TR/wac#authorization-rule).

|**id_acl**|**read_access**|**write_access**|**control_access**|**agent_webid**|**agent_class**|
|----------|---------------|----------------|------------------|---------------|---------------|
|0 |Yes |Yes |Yes |<http://localhost:3012/lindner/profile/card#me> |                                  |
|1 |Yes |No  |No  |                                                |`http://xmlns.com/foaf/0.1/Agent> |

Each row specifies an authorization for a web resource:

* The first row specifies that the agent whose WebId is `http://localhost:3012/lindner/profile/card#me` (our Lindner actor) has read, write and control access.
* The second row specifies that agents whose class is `http://xmlns.com/foaf/0.1/Agent` (in other words: the public, every unauthenticated agent) have read access.

We would like to annotate every product,
generate the corresponding RDF triples
and write them to a first web resource, from here on called the "data resource".

In addition, we would like to annotate Solid's authorization rules,
generate the corresponding RDF triples
and write them to a second web resource: the ACL resource, the web resource linked to the data resource.

### Initial YARRRML document

> From this point on, executing the example mappings requires that our supporting Community Solid Server (CSS) is up and running,
> as explained in [here in the README](README.md#http-output).

Based on what we learned in the using targets tutorial,
the following YARRRML document generates the aforementioned triples for the data resource:

```yaml
prefixes:
  ceon-product: http://w3id.org/CEON/ontology/product/
  e: http://myontology.com/
  ex: http://example.com/

sources:
  source-products: ['tutorial_products.csv~csv']

targets:
  target-products-data:
    type: directhttprequest
    access: http://localhost:3012/lindner/ltargets/products-data
    serialization: turtle
    authentication: auth1

authentications:
  auth1:
    type: cssclientcredentials
    email: lindner@example.com
    password: abc123
    webId: http://localhost:3012/lindner/profile/card#me
    oidcIssuer: http://localhost:3012/

mappings:
  products:
    sources:
      - source-products
    s:
      value: ex:$(Product_id)
      targets:
        - target-products-data
    po:
      - [ a, ceon-product:Product~iri ]
      - [ rdfs:label, $(Product Name) ]
```

The above YARRRML document is available as [example-data/x-domain/lindner/tutorial_ltargets_initial.yml](example-data/x-domain/lindner/tutorial_ltargets_initial.yml).

To produce RDF output,
execute the mapping commands by calling our `map.sh` script:

```bash
./map.sh example-data/x-domain/lindner/tutorial_ltargets_initial.yml
```

We can't see the data that is now available at <http://localhost:3012/lindner/ltargets/products-data> via the next `curl` command,
because as an unauthenticated user, we do not have the right to read the web resource.

```shell
curl http://localhost:3012/lindner/ltargets/products-data
```

Instead, we receive an error message:

```text
{"name":"UnauthorizedHttpError","message":"","statusCode":401,"errorCode":"H401","details":{}}
```

But the resource *is* there! We'll find out below.

### Output locations

By now, we have output our generated RDF triples from the `products` mapping
to a data resource at URL <http://localhost:3012/lindner/ltargets/products-data>, serialized as Turtle.

We also want to output generated RDF triples implementing Solid's authorization rules
to an ACL resource linked to the data resource at URL <http://localhost:3012/lindner/ltargets/products-data>.

The question is: what is the URL of this linked resource?

In the following sections,
we explain what rules we need to achieve this, and
how we write them using YARRRML.

## What rules are needed

In our example,
we need extra rules that define:

* triples implementing Solid's authorization rules for the web resource at URL <http://localhost:3012/lindner/ltargets/products-data>,
* that a web resource linked to the web resource at URL <http://localhost:3012/lindner/ltargets/products-data> contains
  these triples about Solid's authorization rules,
* how that linked web resource is linked to the web resource at URL <http://localhost:3012/lindner/ltargets/products-data>,
* that the triples of that linked web resource are serialized as Turtle,
* the authentication required for writing to that linked web resource.

## How to generate triples for Solid's authorization rules

> This chapter is only essential if you are interested in authorization rules as defined for Solid.
If not, take the complete YARRRML document obtained in this chapter for granted
and continue at [How to output to linked web resources](#how-to-output-to-linked-web-resources).

We now define a new mapping `products-acl` for Solid's [authorization rules](https://solidproject.org/TR/wac#authorization-rule).

Looking back at our [example-data/x-domain/lindner/tutorial_products_acl.csv](example-data/x-domain/lindner/tutorial_products_acl.csv),
we see that each row has the information to produce the triples for one *authorization*:

|**id_acl**|**read_access**|**write_access**|**control_access**|**agent_webid**|**agent_class**|
|----------|---------------|----------------|------------------|---------------|---------------|
|0 |Yes |Yes |Yes |<http://localhost:3012/lindner/profile/card#me> |                                  |
|1 |Yes |No  |No  |                                                |`http://xmlns.com/foaf/0.1/Agent> |

We define a subject URI for the authorization from the `id_acl` column and define that the subject is an `acl:Authorization`:

```yaml
products-acl:
  s:
    value: ex:acl_$(id_acl)
  po:
    - [ a, acl:Authorization~iri ]
```

We define that the subject specifies access to our one and only data resource `http://localhost:3012/lindner/ltargets/products-data`, using the predicate `acl:accessTo`:

```yaml
products-acl:
  s:
    value: ex:acl_$(id_acl)
  po:
    - [ a, acl:Authorization~iri ]
    - [ acl:accessTo, http://localhost:3012/lindner/ltargets/products-data~iri ]
```

Using the predicate `acl:mode`, we add access mode `acl:Read`, only if the value in column "read_access" is equal to "Yes".
To do so, we add a `condition` key and in it use the function `equal` to check the contents in column "read_access".
The access mode will only be added if the function returns true.

Our new YARRRML snippet:

```yaml
products-acl:
  s:
    value: ex:acl_$(id_acl)
  po:
    - [ a, acl:Authorization~iri ]
    - [ acl:accessTo, http://localhost:3012/lindner/ltargets/products-data~iri ]
    - p: acl:mode
      o: acl:Read~iri
      condition:
        function: equal
        parameters:
          - [ str1, $(read_access) ]
          - [ str2, Yes ]
```

We define the agent and/or agent class to whom the autorization applies,
using the predicates `acl:agent` and `acl:agentClass`
and reading the values from "agent_webid" and "agent_class":

```yaml
products-acl:
  s:
    value: ex:acl_$(id_acl)
  po:
    - [ a, acl:Authorization~iri ]
    - [ acl:accessTo, http://localhost:3012/lindner/ltargets/products-data~iri ]
    - p: acl:mode
      o: acl:Read~iri
      condition:
        function: equal
        parameters:
          - [ str1, $(read_access) ]
          - [ str2, Yes ]
    - p: acl:agent
      o:
        value: $(agent_webid)
        type: iri
    - p: acl:agentClass
      o:
        value: $(agent_class)
        type: iri
```

After adding access modes `acl:Write` and `acl:Control` in a similar way as we did for `acl:Read`
and specifying the source for our new mapping `products-acl`,
our complete YARRRML document looks like this:

```yaml
prefixes:
  acl: http://www.w3.org/ns/auth/acl#
  ceon-product: http://w3id.org/CEON/ontology/product/
  e: http://myontology.com/
  ex: http://example.com/

sources:
  source-products: ['tutorial_products.csv~csv']
  source-products-acl: ['tutorial_products_acl.csv~csv']

targets:
  target-products-data:
    type: directhttprequest
    access: http://localhost:3012/lindner/ltargets/products-data
    serialization: turtle
    authentication: auth1

authentications:
  auth1:
    type: cssclientcredentials
    email: lindner@example.com
    password: abc123
    webId: http://localhost:3012/lindner/profile/card#me
    oidcIssuer: http://localhost:3012/

mappings:
  products:
    sources:
      - source-products
    s:
      value: ex:$(Product_id)
      targets:
        - target-products-data
    po:
      - [ a, ceon-product:Product~iri ]
      - [ rdfs:label, $(Product Name) ]

  products-acl:
    sources:
      - source-products-acl
    s:
      value: ex:acl_$(id_acl)
    po:
      - [ a, acl:Authorization~iri ]
      - [ acl:accessTo, http://localhost:3012/lindner/ltargets/products-data~iri ]
      - p: acl:mode
        o: acl:Read~iri
        condition:
          function: equal
          parameters:
            - [ str1, $(read_access) ]
            - [ str2, Yes ]
      - p: acl:mode
        o: acl:Write~iri
        condition:
          function: equal
          parameters:
            - [ str1, $(write_access) ]
            - [ str2, Yes ]
      - p: acl:mode
        o: acl:Control~iri
        condition:
          function: equal
          parameters:
            - [ str1, $(control_access) ]
            - [ str2, Yes ]
      - p: acl:agent
        o:
          value: $(agent_webid)
          type: iri
      - p: acl:agentClass
        o:
          value: $(agent_class)
          type: iri
```

The above YARRRML document is available as [example-data/x-domain/lindner/tutorial_ltargets_auth_rules.yml](example-data/x-domain/lindner/tutorial_ltargets_auth_rules.yml).

To produce RDF output,
execute the mapping commands by calling our `map.sh` script:

```bash
./map.sh example-data/x-domain/lindner/tutorial_ltargets_auth_rules.yml
```

The RDF output from mapping `products-acl` is written to the console:

```turtle
<http://example.com/acl_0> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/ns/auth/acl#Authorization> .
<http://example.com/acl_0> <http://www.w3.org/ns/auth/acl#accessTo> <http://localhost:3012/lindner/ltargets/products-data> .
<http://example.com/acl_0> <http://www.w3.org/ns/auth/acl#agent> <http://localhost:3012/lindner/profile/card#me> .
<http://example.com/acl_0> <http://www.w3.org/ns/auth/acl#mode> <http://www.w3.org/ns/auth/acl#Control> .
<http://example.com/acl_0> <http://www.w3.org/ns/auth/acl#mode> <http://www.w3.org/ns/auth/acl#Read> .
<http://example.com/acl_0> <http://www.w3.org/ns/auth/acl#mode> <http://www.w3.org/ns/auth/acl#Write> .
<http://example.com/acl_1> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/ns/auth/acl#Authorization> .
<http://example.com/acl_1> <http://www.w3.org/ns/auth/acl#accessTo> <http://localhost:3012/lindner/ltargets/products-data> .
<http://example.com/acl_1> <http://www.w3.org/ns/auth/acl#agentClass> <http://xmlns.com/foaf/0.1/Agent> .
<http://example.com/acl_1> <http://www.w3.org/ns/auth/acl#mode> <http://www.w3.org/ns/auth/acl#Read> .
```

## How to output to linked web resources

Now that we have the triples for Solid's authorization rules defining access to `http://localhost:3012/lindner/ltargets/products-data`,
we still have to put them in the right ACL resource, to make them effective.

Luckily, we can discover this in our Solid pod.
We know from [ACL Resource Discovery](https://solidproject.org/TR/wac#acl-resource-discovery)
that we have to send an HTTP request to `http://localhost:3012/lindner/ltargets/products-data`
and read the `Link` Header with the `rel` value of `acl` in the response.
The URL in that `Link` header is the URL of the ACL resource we are looking for.

We can check this with a `curl` command that displays response headers (using the `-i` option):

```shell
curl -i http://localhost:3012/lindner/ltargets/products-data
```

This is the output:

```text
HTTP/1.1 401 Unauthorized
Vary: Accept,Authorization,Origin
X-Powered-By: Community Solid Server
Accept-Ranges: bytes
Access-Control-Allow-Origin: *
Access-Control-Allow-Credentials: true
Access-Control-Expose-Headers: Accept-Patch,Accept-Post,Accept-Put,Allow,Content-Range,ETag,Last-Modified,Link,Location,Updates-Via,WAC-Allow,Www-Authenticate
Content-Type: application/json
Link: <http://localhost:3012/lindner/ltargets/products-data.meta>; rel="describedby"
Link: <http://localhost:3012/.notifications/StreamingHTTPChannel2023/b0>; rel="http://www.w3.org/ns/solid/terms#updatesViaStreamingHttp2023"
Link: <http://localhost:3012/lindner/ltargets/products-data.acl>; rel="acl"
WWW-Authenticate: Bearer scope="openid webid"
Date: Wed, 16 Jul 2025 09:04:05 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked

{"name":"UnauthorizedHttpError","message":"","statusCode":401,"errorCode":"H401","details":{}}
```

Clearly, we do not have access to the contents of the data resource now (hence `HTTP/1.1 401 Unauthorized`),
but this is the Link header we are looking for:

```text
Link: <http://localhost:3012/lindner/ltargets/products-data.acl>; rel="acl"
```

Conclusion: the ACL resource's URL is `http://localhost:3012/lindner/ltargets/products-data.acl`.

> Note: If you ask yourself now "Why all the fuzz, it's just the data resource's URL with `.acl` appended", you are right,
but that is an implementation detail valid for the current version of the [Community Solid Server](https://communitysolidserver.github.io/CommunitySolidServer/)
we are using; it is not in the ACL resource specification.

Now here is (finally!) where linked HTTP request targets come in.
If we assign a linked HTTP request target to a mapping,
the mapping engine will do the discovery for us
and write the RDF output to the linked resource.

We define the linked HTTP request target for our ACL resource as follows:

* it must discover a resource linked to `http://localhost:3012/lindner/ltargets/products-data`;
* it must read the resource's URL in the Link header where `rel="acl"`;
* it must use serialization `turtle`;
* it must use authentication `auth1`.

We do this as follows:

```yaml
target-products-acl:
  type: linkedhttprequest
  access: http://localhost:3012/lindner/ltargets/products-data
  rel: acl
  serialization: turtle
  authentication: auth1
```

We specify that this new target is a target of our `products-acl` mapping and obtain the following complete YARRRML document:

```yaml
prefixes:
  acl: http://www.w3.org/ns/auth/acl#
  ceon-product: http://w3id.org/CEON/ontology/product/
  e: http://myontology.com/
  ex: http://example.com/

sources:
  source-products: ['tutorial_products.csv~csv']
  source-products-acl: ['tutorial_products_acl.csv~csv']

targets:
  target-products-data:
    type: directhttprequest
    access: http://localhost:3012/lindner/ltargets/products-data
    serialization: turtle
    authentication: auth1

  target-products-acl:
    type: linkedhttprequest
    access: http://localhost:3012/lindner/ltargets/products-data
    rel: acl
    serialization: turtle
    authentication: auth1

authentications:
  auth1:
    type: cssclientcredentials
    email: lindner@example.com
    password: abc123
    webId: http://localhost:3012/lindner/profile/card#me
    oidcIssuer: http://localhost:3012/

mappings:
  products:
    sources:
      - source-products
    s:
      value: ex:$(Product_id)
      targets:
        - target-products-data
    po:
      - [ a, ceon-product:Product~iri ]
      - [ rdfs:label, $(Product Name) ]

  products-acl:
    sources:
      - source-products-acl
    s:
      value: ex:acl_$(id_acl)
      targets:
        - target-products-acl
    po:
      - [ a, acl:Authorization~iri ]
      - [ acl:accessTo, http://localhost:3012/lindner/ltargets/products-data~iri ]
      - p: acl:mode
        o: acl:Read~iri
        condition:
          function: equal
          parameters:
            - [ str1, $(read_access) ]
            - [ str2, Yes ]
      - p: acl:mode
        o: acl:Write~iri
        condition:
          function: equal
          parameters:
            - [ str1, $(write_access) ]
            - [ str2, Yes ]
      - p: acl:mode
        o: acl:Control~iri
        condition:
          function: equal
          parameters:
            - [ str1, $(control_access) ]
            - [ str2, Yes ]
      - p: acl:agent
        o:
          value: $(agent_webid)
          type: iri
      - p: acl:agentClass
        o:
          value: $(agent_class)
          type: iri
```

The above YARRRML document is available as [example-data/x-domain/lindner/tutorial_ltargets_auth_rules_linked.yml](example-data/x-domain/lindner/tutorial_ltargets_auth_rules_linked.yml).

To produce RDF output,
execute the mapping commands by calling our `map.sh` script:

```bash
./map.sh example-data/x-domain/lindner/tutorial_ltargets_auth_rules_linked.yml
```

To prove that our mapping works, try again reading <http://localhost:3012/lindner/ltargets/products-data> using `curl`.
Remember, the last time we did so we received `401`, `Unauthorized`.

```shell
curl http://localhost:3012/lindner/ltargets/products-data
```

This time it works. The output is:

```turtle
<http://example.com/Nortec_1234> a <http://w3id.org/CEON/ontology/product/Product>;
  <http://www.w3.org/2000/01/rdf-schema#label> "Nortec" .

<http://example.com/Nortec_1235> a <http://w3id.org/CEON/ontology/product/Product>;
  <http://www.w3.org/2000/01/rdf-schema#label> "Nortec acoustic" .

<http://example.com/acoustic_layer_1235> a <http://w3id.org/CEON/ontology/product/Product>;
  <http://www.w3.org/2000/01/rdf-schema#label> "Acoustic layer" .

<http://example.com/pedestal_1234> a <http://w3id.org/CEON/ontology/product/Product>;
  <http://www.w3.org/2000/01/rdf-schema#label> "Pedestal" .

<http://example.com/pedestal_glue_1234> a <http://w3id.org/CEON/ontology/product/Product>;
  <http://www.w3.org/2000/01/rdf-schema#label> "Pedestal glue" .

<http://example.com/tile_1234> a <http://w3id.org/CEON/ontology/product/Product>;
  <http://www.w3.org/2000/01/rdf-schema#label> "Calcium sulfate panel" .
```

Mission completed!

> Note: we cannot read back what we wrote to the ACL resource.
The above `curl` command is just an indirect proof that it works.
As an unauthenticated user, this time we were able to read the data resource.
This proves at least that our authorization `http://www.example.com/acl_1` works.

However, using the setup of our CSS for easy testing and debugging,
we can inspect our ACL resource on the local file system at `./local-run/data/css12/lindner/ltargets/products-data.acl`.
It has contents:

```turtle
<http://example.com/acl_0> a <http://www.w3.org/ns/auth/acl#Authorization>;
  <http://www.w3.org/ns/auth/acl#accessTo> <http://localhost:3012/lindner/ltargets/products-data>;
  <http://www.w3.org/ns/auth/acl#agent> <http://localhost:3012/lindner/profile/card#me>;
  <http://www.w3.org/ns/auth/acl#mode> <http://www.w3.org/ns/auth/acl#Control>, <http://www.w3.org/ns/auth/acl#Read>,
    <http://www.w3.org/ns/auth/acl#Write> .

<http://example.com/acl_1> a <http://www.w3.org/ns/auth/acl#Authorization>;
  <http://www.w3.org/ns/auth/acl#accessTo> <http://localhost:3012/lindner/ltargets/products-data>;
  <http://www.w3.org/ns/auth/acl#agentClass> <http://xmlns.com/foaf/0.1/Agent>;
  <http://www.w3.org/ns/auth/acl#mode> <http://www.w3.org/ns/auth/acl#Read> .
```

## Wrapping up

Congratulations!
You have created your own YARRRML rules that:

* result in triples for Solid authorization rules,
* output RDF to linked web resources, in our example case to ACL resources.

Good job!
We hope you now understand how to use linked HTTP request targets and enjoyed
our practical example to define Solid authorization rules for a data resource.

## More information

You can find more information in the following:

* [YARRRML specification](https://w3id.org/yarrrml/spec)
* [HTTP Request Access in YARRRML](https://rml.io/yarrrml/spec/access/httprequest/)
* [The Solid project](https://solidproject.org/)
