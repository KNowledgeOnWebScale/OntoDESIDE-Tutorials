# Generating Linked Data with YARRRML: using targets

* [Before we start the tutorial](#before-we-start-the-tutorial)
  * [Learning objective](#learning-objective)
* [Concepts](#concepts)
  * [Targets](#targets)
  * [Basic targets](#basic-targets)
    * [Local file targets](#local-file-targets)
    * [HTTP request targets](#http-request-targets)
  * [Dynamic targets](#dynamic-targets)
* [Example](#example)
  * [Initial YARRRML document](#initial-yarrrml-document)
  * [Different output locations](#different-output-locations)
* [What rules are needed](#what-rules-are-needed)
* [How to output to local files](#how-to-output-to-local-files)
  * [How to define the serialization](#how-to-define-the-serialization)
  * [How to define compression](#how-to-define-compression)
* [How to link targets to mappings](#how-to-link-targets-to-mappings)
* [How to output to web resources](#how-to-output-to-web-resources)
* [How to output to web resources requiring authentication](#how-to-output-to-web-resources-requiring-authentication)
* [How to output to dynamic locations](#how-to-output-to-dynamic-locations)
* [How to output to dynamic locations using different sources](#how-to-output-to-dynamic-locations-using-different-sources)
* [Wrapping up](#wrapping-up)
* [More information](#more-information)

## Before we start the tutorial

### Learning objective

At the end of this tutorial,
you'll be able to manually write YARRRML rules
that output RDF to different locations,
including local files and web resources with and without authentication.

## Concepts

### Targets

A target is a collection of properties describing a location where
the output of an RDF mapping engine goes to and how to access it.

In our getting started tutorial,
we had a single output location: the console output of the mapping engine.

In this tutorial,
we'll learn how to specify targets inside our YARRRML document and
assign them to mappings:

* We can assign multiple targets to one mapping.
* We can assign one target to multiple mappings.

### Basic targets

We'll use the term "basic target" throughout this tutorial where needed to distinguish
targets resulting in output going to local files, optionally with compression, or
web resources, optionally with authentication,
from dynamic targets.
The term is not normative.

#### Local file targets

A local file target is a target resulting in output going to local files.

#### HTTP request targets

An HTTP request target is a target resulting in output going to web resources, using HTTP methods.
We distinguish two types of HTTP request targets:

* Direct HTTP request targets, which write to a web resource.
* Linked HTTP request targets, which write to a web resource that is linked to another web resource.
  We don't cover this type in this tutorial.

### Dynamic targets

A dynamic target is a blueprint for basic targets.
For a dynamic target, a YARRRML interpreter generates output that enables a mapping engine
to compute a basic target,
using one or more fields from each record in the source associated with the dynamic target.
Thus, dynamic targets can result in as many output locations as there are records in its associated source.

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
The information includes an id, product name, description, minimum stock count and some take back indicator.

Also, consider the CSV file [example-data/x-domain/lindner/tutorial_products_dimensions.csv](example-data/x-domain/lindner/tutorial_products_dimensions.csv):

|**Measured_product**|**Length**|**Width**|**Height**|
|--------------------|----------|---------|----------|
|Nortec_1234|600|600|45|
|pedestal_1234|600|600|2000|

It contains the dimensions length, width and height of some products.
The unit used in this file is millimeter.

We would like to annotate every product,
link products to their dimensions, and
generate the corresponding RDF triples.

To simplify the example, we'll only consider length; width and height can be handled similarly.

### Initial YARRRML document

Based on what we learned in the getting started tutorial,
the following YARRRML document generates the aforementioned triples:

```yaml
prefixes:
  ceon-product: http://w3id.org/CEON/ontology/product/
  ceon-quantity: http://w3id.org/CEON/ontology/quantity/
  construction: http://w3id.org/CEON/demo/construction/
  e: http://myontology.com/
  ex: http://example.com/
  qudt: http://qudt.org/schema/qudt/
  qudt-quantitykind: http://qudt.org/vocab/quantitykind/
  qudt-unit: http://qudt.org/vocab/unit/

sources:
  source-products: ['tutorial_products.csv~csv']
  source-dimensions: ['tutorial_products_dimensions.csv~csv']

mappings:
  products:
    sources:
      - source-products
    s: ex:$(Product_id)
    po:
      - [ a, ceon-product:Product~iri ]
      - [ rdfs:label, $(Product Name) ]
      - p: ceon-quantity:hasLength
        o:
          mapping: length
          condition:
            function: equal
            parameters:
              - [str1, $(Product_id), s]
              - [str2, $(Measured_product), o]

  length:
    sources:
      - source-dimensions
    s:
      value: ex:$(Measured_product)-length
    po:
      - [ a, [ceon-quantity:Length~iri, qudt:QuantityValue~iri ] ]
      - [ qudt:numericValue, $(Length), xsd:double ]
      - [ qudt:hasUnit, qudt-unit:MilliM~iri ]
```

The above YARRRML document is available as [example-data/x-domain/lindner/tutorial_targets_initial.yml](example-data/x-domain/lindner/tutorial_targets_initial.yml).

To produce RDF output,
execute the mapping commands by calling our `map.sh` script:

```bash
./map.sh example-data/x-domain/lindner/tutorial_targets_initial.yml turtle
```

### Different output locations

We want to output our generated RDF triples from the `products` and `length` mappings to different locations:

* a local file `out/products.ttl`, serialized as Turtle.
* a local file `out/products-gz.ttl.gz`, serialized as Turtle and gzip-compressed.
* a public web resource at URL <http://localhost:3012/lindner/public/products>, serialized as Turtle.
* a private web resource at URL <http://localhost:3012/lindner/private/products>, serialized as Turtle.
* multiple local files `out/products-<x>.ttl`, serialized as Turtle,
  where `<x>` matches a value of the `Product_id` column of `tutorial_products.csv`.

In the following sections,
we explain what rules we need to achieve this, and
how we write them using YARRRML.

## What rules are needed

We need two sets of rules:

* rules that describe the output locations
* rules that link these output locations the existing mappings

In our example,
we need rules that define:

* that the local file `out/products.ttl` contains the generated triples,
* that the triples of `out/products.ttl` are serialized as Turtle,
* that the local file `out/products.ttl.gz` contains the same content as `out/products.ttl`
  and that it's gzip-compressed.
* that the public web resource at URL <http://localhost:3012/lindner/public/products> contains
  the generated triples,
* that the triples of <http://localhost:3012/lindner/public/products> are serialized as Turtle,
* that the web resource at URL <http://localhost:3012/lindner/private/products> contains
  the generated triples,
* that the triples of <http://localhost:3012/lindner/private/products> are serialized as Turtle,
* the authentication required for writing to <http://localhost:3012/lindner/private/products>,
* that there should be multiple files `out/products-<x>.ttl`,
* that `out/products-<x>.ttl` contains the triples that correspond with
  the row that has `<x>` as value for the `Product_id` column of `tutorial_products.csv`.

## How to output to local files

In our example,
we need to output our RDF to local files, both with and without compression.
We define the corresponding targets via the top-level `targets` collection:

```yaml
targets:
```

We group rules per target and we give them a unique key.
In our example, we use `target-products` as the key for the rules that
define that the triples should be outputted to `out/products.ttl`,
serialized as Turtle:

```yaml
targets:
  target-products:
```

We need to define that the location of the file is `out/products.ttl`.
We do this via the key `access`:

```yaml
targets:
  target-products:
    access: out/products.ttl
```

We can define that `out/products.ttl` is a local file
by using the key `type` with the value `localfile`.
But this is not required because if the value of `access` is a path, then
the `type` is [implicitly](https://rml.io/yarrrml/spec/#type-2) set to `localfile`.

### How to define the serialization

We need to define that the serialization should be Turtle.
We do this via the key `serialization` and value `turtle`:

```yaml
targets:
  target-products:
    access: out/products.ttl
    serialization: turtle
```

We can write this using an array notation as well:

```yaml
targets:
  target-products: [out/products.ttl, turtle]
```

### How to define compression

For the local file `out/products.ttl.gz`,
we use the key `target-products-gz`,
set the value of `access` to `out/products.ttl.gz` and
the value of `serialization` to `turtle`:

```yaml
targets:
  target-products-gz:
    access: out/products.ttl.gz
    serialization: turtle
```

We define that we want compression via the key `compression`.
In our example, we want gzip compression:

```yaml
targets:
  target-products-gz:
    access: out/products.ttl.gz
    serialization: turtle
    compression: gzip
```

We can write this using an array notation as well:

```yaml
targets:
  target-products-gz: [out/products.ttl.gz, turtle, gzip]
```

## How to link targets to mappings

In our example,
we need to link the mappings to the targets `target-products` and `target-products-gz`.
We do this by adding the targets to `subject` mapping using the key `targets`.
For the `products` mapping, this results into:

```yaml
mappings:
  products:
    sources:
      - ['tutorial_products.csv~csv']
    s:
      value: ex:$(Product_id)
      targets:
        - target-products
        - target-products-gz
```

It is also possible to use an inline style.
To do so, we describe our target specifications immediately as values of `targets` of the subject,
rather than in the top-level `targets` collection:

```yaml
mappings:
  products:
    sources:
      - ['tutorial_products.csv~csv']
    s:
      value: ex:$(Product_id)
      targets:
        - ['out/products.ttl', 'turtle']
        - ['out/products-gz.ttl.gz', 'turtle', 'gzip']
```

> This is convenient for targets that appear only in a single mapping.

Our complete YARRRML document looks like this:

```yaml
prefixes:
  ceon-product: http://w3id.org/CEON/ontology/product/
  ceon-quantity: http://w3id.org/CEON/ontology/quantity/
  construction: http://w3id.org/CEON/demo/construction/
  e: http://myontology.com/
  ex: http://example.com/
  qudt: http://qudt.org/schema/qudt/
  qudt-quantitykind: http://qudt.org/vocab/quantitykind/
  qudt-unit: http://qudt.org/vocab/unit/

sources:
  source-products: ['tutorial_products.csv~csv']
  source-dimensions: ['tutorial_products_dimensions.csv~csv']

targets:
  target-products: ['out/products.ttl', 'turtle']
  target-products-gz: ['out/products-gz.ttl.gz', 'turtle', 'gzip']

mappings:
  products:
    sources:
      - source-products
    s:
      value: ex:$(Product_id)
      targets:
        - target-products
        - target-products-gz
    po:
      - [ a, ceon-product:Product~iri ]
      - [ rdfs:label, $(Product Name) ]
      - p: ceon-quantity:hasLength
        o:
          mapping: length
          condition:
            function: equal
            parameters:
              - [str1, $(Product_id), s]
              - [str2, $(Measured_product), o]

  length:
    sources:
      - source-dimensions
    s:
      value: ex:$(Measured_product)-length
      targets:
        - target-products
        - target-products-gz
    po:
      - [ a, [ceon-quantity:Length~iri, qudt:QuantityValue~iri ] ]
      - [ qudt:numericValue, $(Length), xsd:double ]
      - [ qudt:hasUnit, qudt-unit:MilliM~iri ]
```

The above YARRRML document is available as [example-data/x-domain/lindner/tutorial_targets_basic.yml](example-data/x-domain/lindner/tutorial_targets_basic.yml).

To produce RDF output,
execute the mapping commands by calling our `map.sh` script:

```bash
./map.sh example-data/x-domain/lindner/tutorial_targets_basic.yml
```

Now we can view the RDF output in the specified subdirectory `out`, located relatively to our YARRRML documents,
in other words at `example-data/x-domain/lindner/out`:

```bash
ls -1 example-data/x-domain/lindner/out
```

The content of the directory is:

```text
products-gz.ttl.gz
products.ttl
```

Next, we gunzip the gzip file:

```shell
pushd example-data/x-domain/lindner/out
gunzip products-gz.ttl.gz
ls -1
popd
```

Now, the content of the directory is:

```text
products-gz.ttl
products.ttl
```

The contents of the files `products.ttl` and `products-gz.ttl` are identical and equal to:

```turtle
<http://example.com/Nortec_1234> a <http://w3id.org/CEON/ontology/product/Product>;
  <http://w3id.org/CEON/ontology/quantity/hasLength> <http://example.com/Nortec_1234-length>;
  <http://www.w3.org/2000/01/rdf-schema#label> "Nortec" .

<http://example.com/Nortec_1234-length> a <http://qudt.org/schema/qudt/QuantityValue>,
    <http://w3id.org/CEON/ontology/quantity/Length>;
  <http://qudt.org/schema/qudt/hasUnit> <http://qudt.org/vocab/unit/MilliM>;
  <http://qudt.org/schema/qudt/numericValue> 6.0E2 .

<http://example.com/Nortec_1235> a <http://w3id.org/CEON/ontology/product/Product>;
  <http://www.w3.org/2000/01/rdf-schema#label> "Nortec acoustic" .

<http://example.com/acoustic_layer_1235> a <http://w3id.org/CEON/ontology/product/Product>;
  <http://www.w3.org/2000/01/rdf-schema#label> "Acoustic layer" .

<http://example.com/pedestal_1234> a <http://w3id.org/CEON/ontology/product/Product>;
  <http://w3id.org/CEON/ontology/quantity/hasLength> <http://example.com/pedestal_1234-length>;
  <http://www.w3.org/2000/01/rdf-schema#label> "Pedestal" .

<http://example.com/pedestal_1234-length> a <http://qudt.org/schema/qudt/QuantityValue>,
    <http://w3id.org/CEON/ontology/quantity/Length>;
  <http://qudt.org/schema/qudt/hasUnit> <http://qudt.org/vocab/unit/MilliM>;
  <http://qudt.org/schema/qudt/numericValue> 6.0E2 .

<http://example.com/pedestal_glue_1234> a <http://w3id.org/CEON/ontology/product/Product>;
  <http://www.w3.org/2000/01/rdf-schema#label> "Pedestal glue" .

<http://example.com/tile_1234> a <http://w3id.org/CEON/ontology/product/Product>;
  <http://www.w3.org/2000/01/rdf-schema#label> "Calcium sulfate panel" .
```

## How to output to web resources

> From this point on, executing the example mappings requires that our supporting Community Solid Server (CSS) is up and running,
> as explained [here in the README](README.md#http-output).

In our example,
we don't only need to output RDF to local files,
but also to web resources.
Specifically, we need to define that the mapping engine stores the generated triples at <http://localhost:3012/lindner/public/products>.
We add another key-value to the top-level `targets` collection to achieve this:

```yaml
targets:
  target-web:
    type: directhttprequest
    access: http://localhost:3012/lindner/public/products
    methodName: PUT
    headers:
      - name: Content-Type
        value: text/turtle
    serialization: turtle
```

This description instructs the mapping engine to send an HTTP request
to <http://localhost:3012/lindner/public/products>,
using the `PUT` method, with the `Content-Type` header set to `text/turtle`,
and with RDF, serialized as Turtle, in the body.

The default `methodName` is `PUT` and
a YARRRML interpreter derives the `Content-Type` header value `text/turtle` from `serialization: turtle`,
so we can shorten this to:

```yaml
targets:
  target-web:
    type: directhttprequest
    access: http://localhost:3012/lindner/public/products
    serialization: turtle
```

The complete YARRRML document looks like this:

```yaml
prefixes:
  ceon-product: http://w3id.org/CEON/ontology/product/
  ceon-quantity: http://w3id.org/CEON/ontology/quantity/
  construction: http://w3id.org/CEON/demo/construction/
  e: http://myontology.com/
  ex: http://example.com/
  qudt: http://qudt.org/schema/qudt/
  qudt-quantitykind: http://qudt.org/vocab/quantitykind/
  qudt-unit: http://qudt.org/vocab/unit/

sources:
  source-products: ['tutorial_products.csv~csv']
  source-dimensions: ['tutorial_products_dimensions.csv~csv']

targets:
  target-products: ['out/products.ttl', 'turtle']
  target-products-gz: ['out/products-gz.ttl.gz', 'turtle', 'gzip']
  target-web:
    type: directhttprequest
    access: http://localhost:3012/lindner/public/products
    serialization: turtle

mappings:
  products:
    sources:
      - source-products
    s:
      value: ex:$(Product_id)
      targets:
        - target-products
        - target-products-gz
        - target-web
    po:
      - [ a, ceon-product:Product~iri ]
      - [ rdfs:label, $(Product Name) ]
      - p: ceon-quantity:hasLength
        o:
          mapping: length
          condition:
            function: equal
            parameters:
              - [str1, $(Product_id), s]
              - [str2, $(Measured_product), o]

  length:
    sources:
      - source-dimensions
    s:
      value: ex:$(Measured_product)-length
      targets:
        - target-products
        - target-products-gz
        - target-web
    po:
      - [ a, [ceon-quantity:Length~iri, qudt:QuantityValue~iri ] ]
      - [ qudt:numericValue, $(Length), xsd:double ]
      - [ qudt:hasUnit, qudt-unit:MilliM~iri ]
```

The above YARRRML document is available as [example-data/x-domain/lindner/tutorial_targets_web.yml](example-data/x-domain/lindner/tutorial_targets_web.yml).

To produce RDF output,
execute the mapping commands by calling our `map.sh` script:

```bash
./map.sh example-data/x-domain/lindner/tutorial_targets_web.yml
```

We can see the data that is now available at <http://localhost:3012/lindner/public/products> via

```shell
curl http://localhost:3012/lindner/public/products
```

The result is the same as the contents of the files `products.ttl` and `products-gz.ttl`:

```turtle
<http://example.com/Nortec_1234> a <http://w3id.org/CEON/ontology/product/Product>;
  <http://w3id.org/CEON/ontology/quantity/hasLength> <http://example.com/Nortec_1234-length>;
  <http://www.w3.org/2000/01/rdf-schema#label> "Nortec" .

<http://example.com/Nortec_1234-length> a <http://qudt.org/schema/qudt/QuantityValue>,
    <http://w3id.org/CEON/ontology/quantity/Length>;
  <http://qudt.org/schema/qudt/hasUnit> <http://qudt.org/vocab/unit/MilliM>;
  <http://qudt.org/schema/qudt/numericValue> 6.0E2 .

<http://example.com/Nortec_1235> a <http://w3id.org/CEON/ontology/product/Product>;
  <http://www.w3.org/2000/01/rdf-schema#label> "Nortec acoustic" .

<http://example.com/acoustic_layer_1235> a <http://w3id.org/CEON/ontology/product/Product>;
  <http://www.w3.org/2000/01/rdf-schema#label> "Acoustic layer" .

<http://example.com/pedestal_1234> a <http://w3id.org/CEON/ontology/product/Product>;
  <http://w3id.org/CEON/ontology/quantity/hasLength> <http://example.com/pedestal_1234-length>;
  <http://www.w3.org/2000/01/rdf-schema#label> "Pedestal" .

<http://example.com/pedestal_1234-length> a <http://qudt.org/schema/qudt/QuantityValue>,
    <http://w3id.org/CEON/ontology/quantity/Length>;
  <http://qudt.org/schema/qudt/hasUnit> <http://qudt.org/vocab/unit/MilliM>;
  <http://qudt.org/schema/qudt/numericValue> 6.0E2 .

<http://example.com/pedestal_glue_1234> a <http://w3id.org/CEON/ontology/product/Product>;
  <http://www.w3.org/2000/01/rdf-schema#label> "Pedestal glue" .

<http://example.com/tile_1234> a <http://w3id.org/CEON/ontology/product/Product>;
  <http://www.w3.org/2000/01/rdf-schema#label> "Calcium sulfate panel" .
```

## How to output to web resources requiring authentication

In our example,
we need to write to a private web resource at <http://localhost:3012/lindner/private/products>,
which is hosted on a Solid pod.
We can use [Client Credentials Authentication](https://communitysolidserver.github.io/CommunitySolidServer/7.x/usage/client-credentials/)
because we use an instance of the [Community Solid Server (CSS)](https://github.com/CommunitySolidServer/CommunitySolidServer) to host the pod.

The details we need are

* WebID: <http://localhost:3012/lindner/profile/card#me>
* OIDC issuer: <http://localhost:3012/>
* email: `lindner@example.com`
* password: `abc123`

It's not required for this tutorial to know what a WebID and OIDC issuer are.

We add this information to the top-level collection `authentications` using the key `auth1`:

```yaml
authentications:
  auth1:
    type: cssclientcredentials
    email: lindner@example.com
    password: abc123
    webId: http://localhost:3012/lindner/profile/card#me
    oidcIssuer: http://localhost:3012/
 ```

We also need to include a new target for the web resource <http://localhost:3012/lindner/private/products>
and define that the mapping engine needs to use the authentication information
we defined at `auth1` using the `authentication` key:

```yaml
targets:
  target-web-private:
    type: directhttprequest
    access: http://localhost:3012/lindner/private/products
    serialization: turtle
    authentication: auth1
```

The complete YARRRML document looks like this:

```yaml
prefixes:
  ceon-product: http://w3id.org/CEON/ontology/product/
  ceon-quantity: http://w3id.org/CEON/ontology/quantity/
  construction: http://w3id.org/CEON/demo/construction/
  e: http://myontology.com/
  ex: http://example.com/
  qudt: http://qudt.org/schema/qudt/
  qudt-quantitykind: http://qudt.org/vocab/quantitykind/
  qudt-unit: http://qudt.org/vocab/unit/

sources:
  source-products: ['tutorial_products.csv~csv']
  source-dimensions: ['tutorial_products_dimensions.csv~csv']

targets:
  target-products: ['out/products.ttl', 'turtle']
  target-products-gz: ['out/products-gz.ttl.gz', 'turtle', 'gzip']
  target-web:
    type: directhttprequest
    access: http://localhost:3012/lindner/public/products
    serialization: turtle
  target-web-private:
    type: directhttprequest
    access: http://localhost:3012/lindner/private/products
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
        - target-products
        - target-products-gz
        - target-web
        - target-web-private
    po:
      - [ a, ceon-product:Product~iri ]
      - [ rdfs:label, $(Product Name) ]
      - p: ceon-quantity:hasLength
        o:
          mapping: length
          condition:
            function: equal
            parameters:
              - [str1, $(Product_id), s]
              - [str2, $(Measured_product), o]

  length:
    sources:
      - source-dimensions
    s:
      value: ex:$(Measured_product)-length
      targets:
        - target-products
        - target-products-gz
        - target-web
        - target-web-private
    po:
      - [ a, [ceon-quantity:Length~iri, qudt:QuantityValue~iri ] ]
      - [ qudt:numericValue, $(Length), xsd:double ]
      - [ qudt:hasUnit, qudt-unit:MilliM~iri ]
```

The above YARRRML document is available as [example-data/x-domain/lindner/tutorial_targets_web_auth.yml](example-data/x-domain/lindner/tutorial_targets_web_auth.yml).

To produce RDF output,
execute the mapping commands by calling our `map.sh` script:

```bash
./map.sh example-data/x-domain/lindner/tutorial_targets_web_auth.yml
```

We can see the data that is now available at <http://localhost:3012/lindner/private/products> via

```shell
curl http://localhost:3012/lindner/private/products
```

Note that the pod requires authentication to write to the web resource,
but that it doesn't require authentication to read the web resource.
The result is the same as the contents of <http://localhost:3012/lindner/public/products>:

```turtle
<http://example.com/Nortec_1234> a <http://w3id.org/CEON/ontology/product/Product>;
  <http://w3id.org/CEON/ontology/quantity/hasLength> <http://example.com/Nortec_1234-length>;
  <http://www.w3.org/2000/01/rdf-schema#label> "Nortec" .

<http://example.com/Nortec_1234-length> a <http://qudt.org/schema/qudt/QuantityValue>,
    <http://w3id.org/CEON/ontology/quantity/Length>;
  <http://qudt.org/schema/qudt/hasUnit> <http://qudt.org/vocab/unit/MilliM>;
  <http://qudt.org/schema/qudt/numericValue> 6.0E2 .

<http://example.com/Nortec_1235> a <http://w3id.org/CEON/ontology/product/Product>;
  <http://www.w3.org/2000/01/rdf-schema#label> "Nortec acoustic" .

<http://example.com/acoustic_layer_1235> a <http://w3id.org/CEON/ontology/product/Product>;
  <http://www.w3.org/2000/01/rdf-schema#label> "Acoustic layer" .

<http://example.com/pedestal_1234> a <http://w3id.org/CEON/ontology/product/Product>;
  <http://w3id.org/CEON/ontology/quantity/hasLength> <http://example.com/pedestal_1234-length>;
  <http://www.w3.org/2000/01/rdf-schema#label> "Pedestal" .

<http://example.com/pedestal_1234-length> a <http://qudt.org/schema/qudt/QuantityValue>,
    <http://w3id.org/CEON/ontology/quantity/Length>;
  <http://qudt.org/schema/qudt/hasUnit> <http://qudt.org/vocab/unit/MilliM>;
  <http://qudt.org/schema/qudt/numericValue> 6.0E2 .

<http://example.com/pedestal_glue_1234> a <http://w3id.org/CEON/ontology/product/Product>;
  <http://www.w3.org/2000/01/rdf-schema#label> "Pedestal glue" .

<http://example.com/tile_1234> a <http://w3id.org/CEON/ontology/product/Product>;
  <http://www.w3.org/2000/01/rdf-schema#label> "Calcium sulfate panel" .
```

## How to output to dynamic locations

In our example,
we need to add all the triples of one product to one local file.
Specifically, we need to output all triples of the product with the value `<x>` in the column `Product_id`
into the file `out/products-<x>.ttl`, serialized as Turtle.
We do this by using [dynamic targets](https://rml.io/yarrrml/spec/target/dynamictarget/#definitions).
Dynamic targets have the same keys as basic targets, which are now templates instead of static strings,
and an extra one called `source`.
In our example,
`access` has the value `out/products-$(Product_id).ttl` and
`source` has the value `source-products`:

```yaml
targets:
  target-products-dt:
    source: source-products
    access: out/products-$(Product_id).ttl
    serialization: turtle
```

The complete YARRRML document looks like this:

```yaml
prefixes:
  ceon-product: http://w3id.org/CEON/ontology/product/
  ceon-quantity: http://w3id.org/CEON/ontology/quantity/
  construction: http://w3id.org/CEON/demo/construction/
  e: http://myontology.com/
  ex: http://example.com/
  qudt: http://qudt.org/schema/qudt/
  qudt-quantitykind: http://qudt.org/vocab/quantitykind/
  qudt-unit: http://qudt.org/vocab/unit/

sources:
  source-products: ['tutorial_products.csv~csv']
  source-dimensions: ['tutorial_products_dimensions.csv~csv']

targets:
  target-products: ['out/products.ttl', 'turtle']
  target-products-gz: ['out/products-gz.ttl.gz', 'turtle', 'gzip']
  target-web:
    type: directhttprequest
    access: http://localhost:3012/lindner/public/products
    serialization: turtle
  target-web-private:
    type: directhttprequest
    access: http://localhost:3012/lindner/private/products
    serialization: turtle
    authentication: auth1
  target-products-dt:
    source: source-products
    access: out/products-$(Product_id).ttl
    serialization: turtle

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
        - target-products
        - target-products-gz
        - target-web
        - target-web-private
        - target-products-dt
    po:
      - [ a, ceon-product:Product~iri ]
      - [ rdfs:label, $(Product Name) ]
      - p: ceon-quantity:hasLength
        o:
          mapping: length
          condition:
            function: equal
            parameters:
              - [str1, $(Product_id), s]
              - [str2, $(Measured_product), o]

  length:
    sources:
      - source-dimensions
    s:
      value: ex:$(Measured_product)-length
      targets:
        - target-products
        - target-products-gz
        - target-web
        - target-web-private
    po:
      - [ a, [ceon-quantity:Length~iri, qudt:QuantityValue~iri ] ]
      - [ qudt:numericValue, $(Length), xsd:double ]
      - [ qudt:hasUnit, qudt-unit:MilliM~iri ]
```

The above YARRRML document is available as [example-data/x-domain/lindner/tutorial_targets_dynamic.yml](example-data/x-domain/lindner/tutorial_targets_dynamic.yml).

To produce RDF output,
execute the mapping commands by calling our `map.sh` script:

```bash
./map.sh example-data/x-domain/lindner/tutorial_targets_dynamic.yml
```

Now we can view the RDF output in our subdirectory `example-data/x-domain/lindner/out`:

```bash
ls -1 example-data/x-domain/lindner/out
```

The content of the directory is:

```text
products-Nortec_1234.ttl
products-Nortec_1235.ttl
products-acoustic_layer_1235.ttl
products-gz.ttl.gz
products-pedestal_1234.ttl
products-pedestal_glue_1234.ttl
products-tile_1234.ttl
products.ttl
```

There are six files `products-*.ttl`
because there are six records in `tutorial_products.csv` with each a unique value for the column `Product_id`.

The contents of `products-Nortec_1234.ttl`, containing the triples about the first product, is

```turtle
<http://example.com/Nortec_1234> a <http://w3id.org/CEON/ontology/product/Product>;
  <http://w3id.org/CEON/ontology/quantity/hasLength> <http://example.com/Nortec_1234-length>;
  <http://www.w3.org/2000/01/rdf-schema#label> "Nortec" .
```

The contents of `products-pedestal_1234`, containing the triples about the third product, is

```turtle
<http://example.com/pedestal_1234> a <http://w3id.org/CEON/ontology/product/Product>;
  <http://w3id.org/CEON/ontology/quantity/hasLength> <http://example.com/pedestal_1234-length>;
  <http://www.w3.org/2000/01/rdf-schema#label> "Pedestal" .
```

## How to output to dynamic locations using different sources

<!-- I AM HERE -->

In our example,
we need to output triples generated via the `length` mapping also to the files `out/products-$(Product_id).ttl`.
We can't just add `target-products-dt` to the targets of the subject of the `length` mapping,
because the sources of the target and the mapping are different.
We need to add the `id` key to our target:

```yaml
targets:
  target-products-dt:
    source: source-products
    id: id-target-products-dt-$(Product_id)
    access: out/products-$(Product_id).ttl
    serialization: turtle
```

We can now refer to the target via the value of the `id` key.
For example,
if we use `id-target-products-dt-$(Measured_product)`,
then the mapping engine uses the value of `Measured_product` of the processed record of `tutorial_products_dimensions.csv` as
value for `Product_id` of the target's `id`.
This will also determine the value for the `access` key considering they both use `Product_id` in this target.

If we only look at the `length` mapping,
then we add the target as follows:

```yaml
length:
  sources:
    - source-dimensions
  s:
    value: ex:$(Measured_product)-length
    targets:
      - target-products
      - target-products-gz
      - target-web
      - target-web-private
      - id-target-products-dt-$(Measured_product)
  po:
    - [ a, [ceon-quantity:Length~iri, qudt:QuantityValue~iri ] ]
    - [ qudt:numericValue, $(Length), xsd:double ]
    - [ qudt:hasUnit, qudt-unit:MilliM~iri ]
```

The complete YARRRML document looks like this:

```yaml
prefixes:
  ceon-product: http://w3id.org/CEON/ontology/product/
  ceon-quantity: http://w3id.org/CEON/ontology/quantity/
  construction: http://w3id.org/CEON/demo/construction/
  e: http://myontology.com/
  ex: http://example.com/
  qudt: http://qudt.org/schema/qudt/
  qudt-quantitykind: http://qudt.org/vocab/quantitykind/
  qudt-unit: http://qudt.org/vocab/unit/

sources:
  source-products: ['tutorial_products.csv~csv']
  source-dimensions: ['tutorial_products_dimensions.csv~csv']

targets:
  target-products: ['out/products.ttl', 'turtle']
  target-products-gz: ['out/products-gz.ttl.gz', 'turtle', 'gzip']
  target-web:
    type: directhttprequest
    access: http://localhost:3012/lindner/public/products
    serialization: turtle
  target-web-private:
    type: directhttprequest
    access: http://localhost:3012/lindner/private/products
    serialization: turtle
    authentication: auth1
  target-products-dt:
    source: source-products
    id: id-target-products-dt-$(Product_id)
    access: out/products-$(Product_id).ttl
    serialization: turtle

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
        - target-products
        - target-products-gz
        - target-web
        - target-web-private
        - target-products-dt
    po:
      - [ a, ceon-product:Product~iri ]
      - [ rdfs:label, $(Product Name) ]
      - p: ceon-quantity:hasLength
        o:
          mapping: length
          condition:
            function: equal
            parameters:
              - [str1, $(Product_id), s]
              - [str2, $(Measured_product), o]

  length:
    sources:
      - source-dimensions
    s:
      value: ex:$(Measured_product)-length
      targets:
        - target-products
        - target-products-gz
        - target-web
        - target-web-private
        - id-target-products-dt-$(Measured_product)
    po:
      - [ a, [ceon-quantity:Length~iri, qudt:QuantityValue~iri ] ]
      - [ qudt:numericValue, $(Length), xsd:double ]
      - [ qudt:hasUnit, qudt-unit:MilliM~iri ]
```

The above YARRRML document is available as [example-data/x-domain/lindner/tutorial_targets_dynamic_length.yml](example-data/x-domain/lindner/tutorial_targets_dynamic_length.yml).

To produce RDF output,
execute the mapping commands by calling our `map.sh` script:

```bash
./map.sh example-data/x-domain/lindner/tutorial_targets_dynamic_length.yml
```

Now we can view the RDF output in our subdirectory `example-data/x-domain/lindner/out`:

```bash
ls -1 example-data/x-domain/lindner/out
```

The content of the directory is:

```text
products-Nortec_1234.ttl
products-Nortec_1235.ttl
products-acoustic_layer_1235.ttl
products-gz.ttl.gz
products-pedestal_1234.ttl
products-pedestal_glue_1234.ttl
products-tile_1234.ttl
products.ttl
```

The contents of `products-Nortec_1234.ttl`, containing the triples about the first product, is

```turtle
<http://example.com/Nortec_1234> a <http://w3id.org/CEON/ontology/product/Product>;
  <http://w3id.org/CEON/ontology/quantity/hasLength> <http://example.com/Nortec_1234-length>;
  <http://www.w3.org/2000/01/rdf-schema#label> "Nortec" .

<http://example.com/Nortec_1234-length> a <http://qudt.org/schema/qudt/QuantityValue>,
    <http://w3id.org/CEON/ontology/quantity/Length>;
  <http://qudt.org/schema/qudt/hasUnit> <http://qudt.org/vocab/unit/MilliM>;
  <http://qudt.org/schema/qudt/numericValue> 6.0E2 .
```

Note that the mapping engine added the triples with the subject <http://example.com/Nortec_1234-length>.

The contents of `products-pedestal_1234`, containing the triples about the third product, is

```turtle
<http://example.com/pedestal_1234> a <http://w3id.org/CEON/ontology/product/Product>;
  <http://w3id.org/CEON/ontology/quantity/hasLength> <http://example.com/pedestal_1234-length>;
  <http://www.w3.org/2000/01/rdf-schema#label> "Pedestal" .

<http://example.com/pedestal_1234-length> a <http://qudt.org/schema/qudt/QuantityValue>,
    <http://w3id.org/CEON/ontology/quantity/Length>;
  <http://qudt.org/schema/qudt/hasUnit> <http://qudt.org/vocab/unit/MilliM>;
  <http://qudt.org/schema/qudt/numericValue> 6.0E2 .
```

## Wrapping up

Congratulations!
You have created your own YARRRML rules that:

* output RDF to local files,
* compress the output,
* output RDF to web resources,
* use authentication, and
* output RDF to different local files in a dynamic way.

Nice work!
We hope you now feel like you have a decent grasp on how targets in YARRRML work.

## More information

You can find more information in the following:

* [YARRRML specification](https://w3id.org/yarrrml/spec)
* [HTTP Request Access in YARRRML](https://rml.io/yarrrml/spec/access/httprequest/)
* [Dynamic Targets in YARRRML](https://rml.io/yarrrml/spec/target/dynamictarget/)
