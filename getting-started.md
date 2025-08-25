# Generating Linked Data with YARRRML: get started

YARRRML is a human-readable text-based representation for declarative Linked Data generation rules.
It is a subset of [YAML](https://www.yaml.io/), a widely used data serialization language designed to be human-friendly.
It can be used to represent [R2RML](https://www.w3.org/TR/r2rml/), [RML](http://rml.io), and
[SPARQL-Generate](https://ci.mines-stetienne.fr/sparql-generate/) rules.
This tutorial introduces you to YARRRML
by explaining how to generate Linked Data from existing data sources with YARRRML rules.
You can use [Matey](https://w3id.org/yarrrml/matey) to run this tutorial's examples yourself and in the browser.

* [Before we start the tutorial](#before-we-start-the-tutorial)
  * [Learning objective](#learning-objective)
  * [Assumptions](#assumptions)
  * [How to use the tutorial](#how-to-use-the-tutorial)
* [Concepts](#concepts)
  * [Existing data sources](#existing-data-sources)
  * [RDF](#rdf)
    * [Terms](#terms)
    * [Triples](#triples)
    * [Quads](#quads)
    * [Prefixed names](#prefixed-names)
  * [Rules](#rules)
  * [Document](#document)
* [Example](#example)
* [What rules are needed](#what-rules-are-needed)
* [How to start a YARRRML document](#how-to-start-a-yarrrml-document)
* [What data to use](#what-data-to-use)
* [How to generate subjects](#how-to-generate-subjects)
* [How to generate predicates and objects](#how-to-generate-predicates-and-objects)
  * [How to annotate an entity with a class](#how-to-annotate-an-entity-with-a-class)
  * [How to annotate an entity with a property](#how-to-annotate-an-entity-with-a-property)
  * [How to define the datatype of a literal value](#how-to-define-the-datatype-of-a-literal-value)
  * [How to define the language of a literal value](#how-to-define-the-language-of-a-literal-value)
  * [How to link two entities](#how-to-link-two-entities)
* [How to add triples to a graph](#how-to-add-triples-to-a-graph)
  * [How to add all triples to a graph](#how-to-add-all-triples-to-a-graph)
  * [How to add po-specific triples to a graph](#how-to-add-po-specific-triples-to-a-graph)
* [How to transform the data](#how-to-transform-the-data)
* [Complete YARRRML document](#complete-yarrrml-document)
* [Other data formats](#other-data-formats)
  * [JSON](#json)
  * [XML](#xml)
* [Wrapping up](#wrapping-up)
* [More information](#more-information)

## Before we start the tutorial

### Learning objective

At the end of the tutorial
you will be able to generate RDF
from multiple, existing data sources in different formats
by manually writing YARRRML rules.

### Assumptions

We assume that you understand Linked Data and more specific the
[Resource Description Framework](https://www.w3.org/TR/rdf11-concepts/) (RDF).
However, the basic concepts of RDF are explained in this tutorial.
We assume the concepts of vocabularies and ontologies, such as classes, properties, and datatypes, are known.

### How to use the tutorial

There are two ways to complete this tutorial:
you read the explanations and either

* just read the examples
* try out the examples yourself

If you want to try out the examples yourself, consult the documentation on the [our working environment in README](./README.md#the-working-environment).

## Concepts

### Existing data sources

The existing data sources contain the data that you want to annotate.
These data can be in different formats, such as CSV, XML, and JSON, and
they can come from different origins, such as files, databases, and Web APIs.

### RDF

In this section, we give a short recap of RDF terms, triples, and quads.

#### Terms

Data in the RDF is represented using either an
[Internationalized Resource Identifier (IRI)](https://www.w3.org/TR/rdf11-concepts/#section-IRIs),
a [literal](https://www.w3.org/TR/rdf11-concepts/#section-Graph-Literal), or
a [blank node](https://www.w3.org/TR/rdf11-concepts/#section-blank-nodes).
They are known as RDF terms.

IRIs are a generalization of [URIs](http://www.ietf.org/rfc/rfc3986.txt) that
permits a wider range of Unicode characters.
For example, `http://example.com/john` and `http://example.com/country/belgium`.

Literals are used for values such as strings, numbers, and dates.
A literal consists of two or three elements:

* a lexical form, for example, "John"
* a datatype IRI, for example, `http://www.w3.org/2001/XMLSchema#string`
* if and only if the datatype IRI is `http://www.w3.org/1999/02/22-rdf-syntax-ns#langString`: a non-empty language tag, for example, "en"

Blank nodes are disjoint from IRIs and literals.
Unlike IRIs and literals, blank nodes do not identify specific resources.
Statements involving blank nodes say that something with the given relationships exists, without explicitly naming it.

#### Triples

An RDF triple consists of three components:

* the subject, which is an IRI or a blank node
* the predicate, which is an IRI
* the object, which is an IRI, a literal or a blank node

A triple is conventionally written in the order subject, predicate, object.

#### Quads

An RDF quad consists of four components:

* the subject, which is an IRI or a blank node
* the predicate, which is an IRI
* the object, which is an IRI, a literal or a blank node
* the graph, which is an IRI or a blank node

A quad is conventionally written in the order subject, predicate, object, graph.

#### Prefixed names

IRIs may be written as [prefixed names](https://www.w3.org/TR/turtle/#sec-iri).
Therefore, a prefix and the corresponding namespace need to be defined.
For example, if we define "ex" as the prefix for the namespace `http://example.com`,
then we can write '<http://example.com/john>' as `ex:john`.

### Rules

YARRRML rules are declarative rules that define how RDF is generated by annotating multiple, existing data sources.

### Document

YARRRML rules are contained in a [document](http://yaml.org/spec/1.2/spec.html#id2800132).

## Example

Consider the following CSV file called "[tutorial_products](example-data/x-domain/lindner/tutorial_products.csv)":

|**Product_id**|**Product Name**|**Product description**|**Minimum stock count**|**Take back program original manufacturer**|
|--------------|----------------|-----------------------|-----------------------|-------------------------------------------|
|Nortec_1234|Nortec|"fibre-reinforced calcium sulphate panel, (...)"|100|YES|
|tile_1234|Calcium sulfate panel||200|YES|
|pedestal_1234|Pedestal||300|YES|
|pedestal_glue_1234|Pedestal glue||400|YES|
|Nortec_1235|Nortec acoustic|"fibre-reinforced calcium sulphate panel with acoustic layer, (...)"|500|YES|
|acoustic_layer_1235|Acoustic layer||600|YES|

It contains information about six different products, corresponding with the six rows.
The information includes an id, product name, description, minimum stock count and some take back indicator.

We would like to annotate every product and generate the corresponding RDF triples and quads.

For example, consider the product described in the first row:

`Nortec_1234,Nortec,"fibre-reinforced calcium sulphate panel, (...)",100,YES,`

We need to define the IRI (or blank node) that represents this product,
which will be used in the triples and quads that provide information about this product.
We will use the concatenation of "<http://example.com/>" and the Product_id as IRI.
This results in `ex:Nortec_1234` for this product, when using the prefix `ex` for `http://example.com/`.

We annotate every product with the class `ceon-product:Product` (`http://w3id.org/CEON/ontology/product/Product`).
This results in the predicate and object: `a ceon-product:Product`.
Furthermore, this results in the triple `ex:Nortec_1234 a ceon-product:Product`,
by combining this predicate and object with the aforementioned subject.

We annotate the product name with the property `rdfs:label` (`http://www.w3.org/2000/01/rdf-schema#label`).
This results in the predicate and object: `rdfs:label "Nortec"`.

We annotate the product description with the property `e:hasProductDescription` (`http://myontology.com/hasProductDescription`) and
additionally say that the description is written in the English language.
This results in the predicate and object: `e:hasProductDescription "fibre-reinforced calcium sulphate panel, (...)"@en`.

We annotate the minimum stock count with the property `e:minimumStockCount`and
additionally say that the number is an integer via the datatype `xsd:integer`.

We annotate the product take back indicator "Take back program original manufacturer" with the property `construction:hasTakeBackProgramFromOriginalManufacturer` (`http://w3id.org/CEON/demo/construction/hasTakeBackProgramFromOriginalManufacturer`).
This results in the predicate and object: `construction:hasTakeBackProgramFromOriginalManufacturer "YES"`.

The resulting RDF triples are

```turtle
ex:Nortec_1234 a ceon-product:Product .
ex:Nortec_1234 rdfs:label "Nortec" .
ex:Nortec_1234 e:hasProductDescription "fibre-reinforced calcium sulphate panel, (...)"@en .
ex:Nortec_1234 e:minimumStockCount "100"^^<http://www.w3.org/2001/XMLSchema#integer> . 
ex:Nortec_1234 construction:hasTakeBackProgramFromOriginalManufacturer "YES" .
```

In the following sections,
we explain what rules you need to generate such triples, and
how you write them using YARRRML.

## What rules are needed

Two sets of rules are needed:

* rules that describe the existing data sources
* rules that define how the RDF terms are generated from these data sources,
and how these terms are used to generate triples and quads.

In our example, we need rules that define:

* how the IRI representing a product is generated,
* that this IRI is used as subject of the triples and quads,
* that the class of a product is `ceon-product:Product`,
* that the product name is annotated with the property `rdfs:label`,
* that the product description is annotated with the property `e:hasProductDescription`,
* that the product description is provided in the English language,
* that the minimum stock count ia annotated with the property `e:minimumStockCount`,
* that the minimum stock count is of the datatype `xsd:integer`,
* that the take bake indicator "Take back program original manufacturer" is annotated with the property `construction:hasTakeBackProgramFromOriginalManufacturer`,
* that a product has dimensions length, width and height.

Furthermore, we want to add certain triples to specific graphs:

* all triples of products to the graph `ex:Products`, and
* all dimension-related triples of products to the graph `ex:Dimensions`.

## How to start a YARRRML document

A minimum YARRRML document looks as follows:

```yaml
mappings:
```

Rules that describe entities are found under [`mappings`](https://w3id.org/yarrrml/spec/#mappings),
which is at the root of the document.
It is possible that more than one entity needs to be described.
Therefore, rules are grouped per entity and are given a unique key.
In this example, we use `products` as the key for the products.

> Note that `products` has to be indented with at least one space to make it part of `mappings`.
Indention has a very special meaning in YARRRML, as in YAML: child elements are indented more than the parent element.

```yaml
mappings:
  products:
```

A set of [prefixes and namespaces](https://www.w3.org/2011/rdfa-context/rdfa-1.1) are predefined by default.
Custom prefixes can be added by adding to the key `prefixes`,
which is at the root at the document.
Each combination of a prefix and namespace is added to this collection as a key-value pair.
In the following example four prefixes are defined: "construction", "ex", "e" and "grel".

```yaml
prefixes:
  construction: http://w3id.org/CEON/demo/construction/
  ex: http://www.example.com/
  e: http://myontology.com/
  grel: http://users.ugent.be/~bjdmeest/function/grel.ttl#
```

> Note that similar to `products` here `construction`, `ex`, `e` and `grel` have to be indented with at least one space.

> When you define a prefix that is also a default prefix,
then it is overwritten by your namespace.

## What data to use

We need two or three elements to describe which data is used:

* location of the data source (via the key `access`)
* how  we refer to the data within the data source (via the key `referenceFormulation`)
* how we iterate over the data (via the key `iterator`; optional)

The product data in our example is in a CSV file called "tutorial_products.csv".
We describe that in YARRRML via

```yaml
access: tutorial_products.csv
referenceFormulation: csv
```

> Note that in the case of CSV we iterate over all rows.
Thus, you do not need to provide how to iterate over the data.
For other formats, such as JSON and XML, you need the iterator (discussed [later on](#other-data-formats)).

We add this value to [`sources`](https://w3id.org/yarrrml/spec/#data-sources),
which is part of `products`:

```yaml
mappings:
  products:
    sources:
      - access: tutorial_products.csv
        referenceFormulation: csv
```

There is also a shorter way to write this: `[tutorial_products.csv~csv]`.
The value of `access` is written before `~` and the value of `referenceFormulation` after.
Optionally, put the string in quotes to be safe for special characters `['tutorial_products.csv~csv']`.
The result is

```yaml
mappings:
  products:
    sources:
      - [tutorial_products.csv~csv]
```

## How to generate subjects

We define how the IRI of a product is generated.
This IRI is used as the subject of the RDF triples for the entity.
We add this definition by adding a new value to `s` (short for [`subjects`](https://w3id.org/yarrrml/spec/#subjects)).

```yaml
mappings:
  products:
    sources:
      - ['tutorial_products.csv~csv']
    s: ex:$(Product_id)
```

The value `ex:$(Product_id)` states that the prefix `ex` is concatenated with the value of the column "Product_id".
The use of `$(...)` allows to use values of the data sources.
In this case, we can refer to values in the different columns.
This specific rule results in the following IRIs as subjects for the products: `ex:Nortec_1234`, `ex:tile_1234`, `ex:pedestal_1234`, `ex:pedestal_glue_1234`, `ex:Nortec_1235` and `ex:acoustic_layer_1235`.

## How to generate predicates and objects

### How to annotate an entity with a class

In our example, we need to annotate every product with the class [`ceon-product:Product`](http://w3id.org/CEON/ontology/product/Product).
This is done by adding a value, with the keys `p` and `o` to [`po`](https://w3id.org/yarrrml/spec/#predicates-and-objects).
`p` has the value for the predicate, and
`o` has the value for the object

```yaml
mappings:
  products:
    sources:
      - ['tutorial_products.csv~csv']
    s: ex:$(Product_id)
    po:
      - p: a
        o: ceon-product:Product
```

The following triples are generated using these rules.

```turtle
ex:Nortec_1234 a ceon-product:Product .
ex:tile_1234 a ceon-product:Product .
ex:pedestal_1234 a ceon-product:Product .
ex:pedestal_glue_1234 a ceon-product:Product .
ex:Nortec_1235 a ceon-product:Product .
ex:acoustic_layer_1235 a ceon-product:Product .
```

Note that `a` is shortcut for `rdf:type`.
Thus,

```yaml
p: a
o: ceon-product:Product
```

is the same as

```yaml
p: rdf:type
o: ceon-product:Product
```

There is a shortcut version available for this via the array notation: `[a, ceon-product:Product]`.
The value is an array where the first element is the predicate (`a`, the value of the key `p`) and
the second element the object (`ceon-product:Product`, the value of the key `o`).

```yaml
mappings:
  products:
    sources:
      - ['tutorial_products.csv~csv']
    s: ex:$(Product_id)
    po:
      - [a, ceon-product:Product]
```

### How to annotate an entity with a property

We define that every product is annotated with its product name,
which can be found in the column "Product Name",
via `rdfs:label`.
This is done by adding another array value to `po`.

```yaml
mappings:
  products:
    sources:
      - ['tutorial_products.csv~csv']
    s: ex:$(Product_id)
    po:
      - [a, ceon-product:Product]
      - [rdfs:label, $(Product Name)]
```

The array is `[rdfs:label, $(Product Name)]`, where `rdfs:label` is the first element (predicate)
and `$(Product Name)` the second element (object).
Note that the latter will take the value in the column "Product Name" and use that as object,
because "Product Name" is enclosed with `$(...)`.

The following triples are generated using these rules.

```turtle
ex:Nortec_1234 a ceon-product:Product .
ex:Nortec_1234 rdfs:label "Nortec" .
ex:tile_1234 a ceon-product:Product .
ex:tile_1234 rdfs:label "Calcium sulfate panel" .
ex:pedestal_1234 a ceon-product:Product .
ex:pedestal_1234 rdfs:label "Pedestal" .
ex:pedestal_glue_1234 a ceon-product:Product .
ex:pedestal_glue_1234 rdfs:label "Pedestal glue" .
ex:Nortec_1235 a ceon-product:Product .
ex:Nortec_1235 rdfs:label "Nortec acoustic" .
ex:acoustic_layer_1235 a ceon-product:Product .
ex:acoustic_layer_1235 rdfs:label "Acoustic layer" .
```

Next, we define that every product is annotated with a take back indicator,
which can be found in the column "Take back program original manufacturer",
via `construction:hasTakeBackProgramFromOriginalManufacturer`.
This is done by adding `[ construction:hasTakeBackProgramFromOriginalManufacturer, $(Take back program original manufacturer) ]` to `po`.

```yaml
mappings:
  products:
    sources:
      - ['tutorial_products.csv~csv']
    s: ex:$(Product_id)
    po:
      - [a, ceon-product:Product]
      - [rdfs:label, $(Product Name)]
      - [construction:hasTakeBackProgramFromOriginalManufacturer, $(Take back program original manufacturer) ]
```

The following triples are generated using these rules.

```turtle
ex:Nortec_1234 a ceon-product:Product .
ex:Nortec_1234 rdfs:label "Nortec" .
ex:Nortec_1234 construction:hasTakeBackProgramFromOriginalManufacturer "YES" .
ex:tile_1234 a ceon-product:Product .
ex:tile_1234 rdfs:label "Calcium sulfate panel" .
ex:tile_1234 construction:hasTakeBackProgramFromOriginalManufacturer "YES" .
ex:pedestal_1234 a ceon-product:Product .
ex:pedestal_1234 rdfs:label "Pedestal" .
ex:pedestal_1234 construction:hasTakeBackProgramFromOriginalManufacturer "YES" .
ex:pedestal_glue_1234 a ceon-product:Product .
ex:pedestal_glue_1234 rdfs:label "Pedestal glue" .
ex:pedestal_glue_1234 construction:hasTakeBackProgramFromOriginalManufacturer "YES" .
ex:Nortec_1235 a ceon-product:Product .
ex:Nortec_1235 rdfs:label "Nortec acoustic" .
ex:Nortec_1235 construction:hasTakeBackProgramFromOriginalManufacturer "YES" .
ex:acoustic_layer_1235 a ceon-product:Product .
ex:acoustic_layer_1235 rdfs:label "Acoustic layer" .
ex:acoustic_layer_1235 construction:hasTakeBackProgramFromOriginalManufacturer "YES" .
```

### How to define the datatype of a literal value

We define that every product is annotated with its minimum stock count,
which can be found in the column "Minimum stock count",
via `e:minimumStockCount`.
This is done by adding the following to `po`:

```yaml
p: e:minimumStockCount
o:
  value: $(Minimum stock count)
```

The following extra triples are generated using this specific rule.

```turtle
ex:Nortec_1234 e:minimumStockCount "100" .
ex:tile_1234 e:minimumStockCount "200" .
ex:pedestal_1234 e:minimumStockCount "300" .
ex:pedestal_glue_1234 e:minimumStockCount "400" .
ex:Nortec_1235 e:minimumStockCount "500" .
ex:acoustic_layer_1235 e:minimumStockCount "600" .
```

However, we want to say that the literal value is of the datatype `xsd:integer`.
For example, for the first triple we want the object to be `"100"^^xsd:integer`.
This can be achieved by updating the rule to:

```yaml
p: e:minimumStockCount
o:
  value: $(Minimum stock count)
  datatype: xsd:integer
```

The key [`datatype`](https://w3id.org/yarrrml/spec/#x7-4-datatypes) is added with the desired datatype `xsd:integer` as value.
The resulting triples are

```turtle
ex:Nortec_1234 e:minimumStockCount "100"^^xsd:integer .
ex:tile_1234 e:minimumStockCount "200"^^xsd:integer .
ex:pedestal_1234 e:minimumStockCount "300"^^xsd:integer .
ex:pedestal_glue_1234 e:minimumStockCount "400"^^xsd:integer .
ex:Nortec_1235 e:minimumStockCount "500"^^xsd:integer .
ex:acoustic_layer_1235 e:minimumStockCount "600"^^xsd:integer .
```

The shortcut version for values of `po` can also be used in this case:
`[e:minimumStockCount, $(Minimum stock count), xsd:integer]`.
Here a third element is added to the array: `xsd:integer`, which is the desired datatype.

### How to define the language of a literal value

We define that every product is annotated with a product description,
if one is available in the column "Product description",
via `e:hasProductDescription`.
This is done by adding `[ e:hasProductDescription, $(Product description), en~lang ]` to `po`.

```yaml
p: e:hasProductDescription
o:
  value: $(Product description)
```

The following extra triples are generated using this specific rule.

```turtle
ex:Nortec_1234 e:hasProductDescription "fibre-reinforced calcium sulphate panel, (...)" .
ex:Nortec_1235 e:hasProductDescription "fibre-reinforced calcium sulphate panel with acoustic layer, (...)" .
```

However, we want to say that the literal value is in English.
For example, for the first triple we want the object to be `"fibre-reinforced calcium sulphate panel, (...)"@en`.
This can be achieved by updating the rule to:

```yaml
p: e:hasProductDescription
o:
  value: $(Product description)
  language: en
```

The key [`language`](https://w3id.org/yarrrml/spec/#languages) is added with
the desired language `en` (i.e., English) as value.
The resulting triples are

```turtle
ex:Nortec_1234 e:hasProductDescription "fibre-reinforced calcium sulphate panel, (...)"@en .
ex:Nortec_1235 e:hasProductDescription "fibre-reinforced calcium sulphate panel with acoustic layer, (...)"@en .
```

The shortcut version for values of `po` can also be used in this case:
`[ e:hasProductDescription, $(Product description), en~lang ]`.
Here a third element is added to the array: `en~lang`, which is the desired language `en` together with `~lang`.
Without `~lang` the value will be considered a datatype.

> Note that you cannot define a datatype and language at the same time,
as the datatype of a literal with a language-tag is [predefined](https://www.w3.org/TR/rdf11-concepts/#section-Graph-Literal).

### How to link two entities

We need to link the dimensions length, width and height with the products.
This information is available in the file "[tutorial_products_dimensions.csv](example-data/x-domain/lindner/tutorial_products_dimensions.csv)":

|**Measured_product**|**Length**|**Width**|**Height**|
|--------------------|----------|---------|----------|
|Nortec_1234|600|600|45|
|pedestal_1234|600|600|2000|

The unit used in this file is millimeter.

To simplify the example, we'll only consider length; width and height can be handled similarly.

We define the following rules:

```yaml
mappings:
  length:
    sources:
      - ['tutorial_products_dimensions.csv~csv']
    s:
      value: ex:$(Measured_product)-length
    po:
      - [ a, [ceon-quantity:Length~iri, qudt:QuantityValue~iri ] ]
      - [ qudt:numericValue, $(Length), xsd:double ]
      - [ qudt:hasUnit, qudt-unit:MilliM~iri ]
```

Every length is a [`ceon-quantity:Length~iri`](http://w3id.org/CEON/ontology/quantity/Length)
and a [`qudt:QuantityValue~iri`](http://qudt.org/schema/qudt/QuantityValue)
and is annotated with its value via [`qudt:numericValue`](http://qudt.org/schema/qudt/numericValue).

The unit of the length is millimeter.
This is expressed by annotating it with [`qudt-unit:MilliM~iri`](http://qudt.org/vocab/unit/MilliM) via [`qudt:hasUnit`](http://qudt.org/schema/qudt/hasUnit).

The following triples are generated.

```turtle
ex:Nortec_1234-length a qudt:QuantityValue, ceon-quantity:Length;
  qudt:hasUnit qudt-unit:MilliM;
  qudt:numericValue 6.0E2 .

ex:pedestal_1234-length a qudt:QuantityValue, ceon-quantity:Length;
  qudt:hasUnit qudt-unit:MilliM;
  qudt:numericValue 6.0E2 .
```

We need to link the lengths with the products.
There is a [relationship](https://w3id.org/yarrrml/spec/#referring-to-other-mappings) established between
the two via the "Product_id" field of a product and the "Measured_product" field of a length.
Thus, we add the following rules for the products:

```yaml
po:
  - p: ceon-quantity:hasLength
    o:
      mapping: length
      condition:
        function: equal
        parameters:
          - [str1, $(Product_id), s]
          - [str2, $(Measured_product), o]
```

`p: ceon-quantity:hasLength` states that we want to use the predicate `ceon-quantity:hasLength`.

`mapping: length` states that we want to create a link between the products and the episodes,
which are identified by the key `length`.

`condition` defines when products and lengths are linked.
More specific, links are only made when "Product_id" of a product _equals_ "Measured_product" of a length.

`function: equals` define that the equal function is used.
This function has two parameters: `str1` and `str2`.
Therefore, `parameters` has two elements.

`- [str1, $(Product_id), s]` states that the value of "Product_id" is coming from
the subject of the triples (via `s` at the end),
which is the product, and is used as value for `str1`.

`- [str2, $(Measured_product), o]` states that the value of "Measured_product" is coming from the object of the triples (via `o` at the end),
which is the product whose length was measured, and is used as value for `str2`.

> Note that `str1` and `str2` can be switched as this does not influence the result of the equal function.

This results in the following extra triples:

```turtle
ex:Nortec_1234 ceon-quantity:hasLength ex:Nortec_1234-length .
ex:pedestal_1234 ceon-quantity:hasLength ex:pedestal_1234-length .
```

> Note that for `ex:tile_1234`, `ex:pedestal_glue_1234`, `ex:Nortec_1235` and `ex:acoustic_layer_1235` no triple is generated
> as lengths for these products are not provided.

## How to add triples to a graph

It is possible to add _all_ triples to graphs and _po-specific_ triples to a graphs, and by doing so generating quads.

### How to add all triples to a graph

We need to add all triples about products to the graph `ex:Products`.
This is done by adding the key [`graphs`](https://w3id.org/yarrrml/spec/#all-triples) to `products`,
together with the corresponding value that defines the graph.

```yaml
mappings:
  products:
    graphs: ex:Products
```

> Note that it is possible to use `$(...)` in the same way as for the subject, predicate, and object.

The following quads are generated for the first product.

```turtle
ex:Nortec_1234 a ceon-product:Product ex:Products .
ex:Nortec_1234 e:hasProductDescription "fibre-reinforced calcium sulphate panel, (...)"@en ex:Products .
ex:Nortec_1234 e:minimumStockCount "100"^^<http://www.w3.org/2001/XMLSchema#integer> ex:Products .
ex:Nortec_1234 ceon-quantity:hasLength ex:Nortec_1234-length ex:Products .
```

### How to add po-specific triples to a graph

We need to add po-specific triples about products to the graph `ex:Dimensions`.
More specific, all triples that are related to dimensions should be in a separate graph.
This is done by adding the key [`graphs`](https://w3id.org/yarrrml/spec/#all-triples-with-a-specific-predicate-and-object) to the sixth element of `po` in the mapping `products,
together with the corresponding value that defines the graph.

We also added `graphs: ex:Dimensions` to the mapping `length`,
as learned in [How to add all triples to a graph](#how-to-add-all-triples-to-a-graph).

```yaml
mappings:
  products:
    graphs: ex:Products
    po:
      - [ a, ceon-product:Product~iri ]
      - [ rdfs:label, $(Product Name) ]
      - [ construction:hasTakeBackProgramFromOriginalManufacturer, $(Take back program original manufacturer) ]
      - [ e:minimumStockCount, $(Minimum stock count), xsd:integer ]
      - [ e:hasProductDescription, $(Product description), en~lang ]
      - p: ceon-quantity:hasLength
        o:
          mapping: length
          condition:
            function: equal
            parameters:
              - [str1, $(Product_id), s]
              - [str2, $(Measured_product), o]
        g: ex:Dimensions
  length:
    graphs: ex:Dimensions
    sources:
      - ['tutorial_products_dimensions.csv~csv']
    s:
      value: ex:$(Measured_product)-length
    po:
      - [ a, [ceon-quantity:Length~iri, qudt:QuantityValue~iri ] ]
      - [ qudt:numericValue, $(Length), xsd:double ]
      - [ qudt:hasUnit, qudt-unit:MilliM~iri ]
```

> Note that graphs cannot be assigned to po-specific triples defined using the array-based notation,
so expand the array-based notation if needed.

> Note that `g` is a shortcut for `graphs`.

For the first product, the following extra quads are generated in the graph ´ex:Dimensions`.

```turtle
ex:Nortec_1234 ceon-quantity:hasLength ex:Nortec_1234-length ex:Dimensions .
ex:Nortec_1234-length a qudt:QuantityValue ex:Dimensions .
ex:Nortec_1234-length a ceon-quantity:Length ex:Dimensions .
ex:Nortec_1234-length qudt:numericValue "600"^^<http://www.w3.org/2001/XMLSchema#double> ex:Dimensions .
ex:Nortec_1234-length qudt:hasUnit qudt-unit:MilliM ex:Dimensions .
```

## How to transform the data

It is possible to transform the existing data before using it in the triples and quads, by applying functions.

In our example, we need to transform the product take back indicator "Take back program original manufacturer" to a boolean value.
This is done by replacing `[ construction:hasTakeBackProgramFromOriginalManufacturer, $(Take back program original manufacturer) ]` with

```yaml
p: construction:hasTakeBackProgramFromOriginalManufacturer
o:
  function: idlab-fn:equal
  parameters:
    - [ grel:valueParameter, $(Take back program original manufacturer) ]
    - [ grel:valueParameter2, YES ]
  datatype: xsd:boolean
```

We call the function `idlab-fn:equal` (defined via the key `function`)
with the value of "Take back program original manufacturer" as the value for the first parameter `grel:valueParameter`
and with the string `YES` as the value for the second parameter (both via the key `parameters`),
which are required for this function.

The full description of the function and its parameters is:

```turtle
idlab-fn:equal
    a                   fno:Function ;
    fno:name            "equal" ;
    rdfs:label          "equal" ;
    dcterms:description "Returns true if strings are equal." ;
    fno:expects         ( grel:valueParam grel:valueParam2 ) ;
    fno:returns         ( idlab-fn:_boolOut ) .

grel:valueParam
    a             fno:Parameter ;
    fno:name      "input value" ;
    rdfs:label    "input value" ;
    fno:type      xsd:string ;
    fno:predicate grel:valueParameter .

grel:valueParam2
    a             fno:Parameter ;
    fno:name      "input value 2" ;
    rdfs:label    "input value 2" ;
    fno:type      xsd:string ;
    fno:predicate grel:valueParameter2 .

idlab-fn:_boolOut
    a             fno:Output ;
    fno:name      "output boolean" ;
    rdfs:label    "output boolean" ;
    fno:type      xsd:boolean ;
    fno:predicate idlab-fn:o_boolOut .
```

The value that is used for `function` can be found on the first line of the description (`idlab-fn:equal`).

The first parameter `grel:valueParam` is described starting on line nine.
The triple with the predicate `fno:predicate` defines the name of the parameter,
which is used in the rules (`grel:valueParameter`).

The second parameter `grel:valueParam2` is described starting on line sixteen.
The triple with the predicate `fno:predicate` defines the name of the parameter,
which is used in the rules (`grel:valueParameter2`).

The function is linked to its parameters via the triple with the predicate `fno:expects`.

> Note that functions, including their parameters and implementations, are defined outside YARRRML.
Thus, custom functions can be added at all times by anyone.

The following triples are generated.

```turtle
ex:Nortec_1234 construction:hasTakeBackProgramFromOriginalManufacturer "true"^^<http://www.w3.org/2001/XMLSchema#boolean> .
ex:tile_1234 construction:hasTakeBackProgramFromOriginalManufacturer "true"^^<http://www.w3.org/2001/XMLSchema#boolean> .
ex:pedestal_1234 construction:hasTakeBackProgramFromOriginalManufacturer "true"^^<http://www.w3.org/2001/XMLSchema#boolean> .
ex:pedestal_glue_1234 construction:hasTakeBackProgramFromOriginalManufacturer "true"^^<http://www.w3.org/2001/XMLSchema#boolean> .
ex:Nortec_1235 construction:hasTakeBackProgramFromOriginalManufacturer "true"^^<http://www.w3.org/2001/XMLSchema#boolean> .
ex:acoustic_layer_1235 construction:hasTakeBackProgramFromOriginalManufacturer "true"^^<http://www.w3.org/2001/XMLSchema#boolean> .
```

The function `idlab-fn:equal` is so commonly used, that the YARRRML parser provides a shortcut for the function name and its parameters.

Without shortcut:

```yaml
function: idlab-fn:equal
parameters:
  - [ grel:valueParameter, $(Take back program original manufacturer) ]
  - [ grel:valueParameter2, YES ]
```

With shortcut:

```yaml
function: equal
parameters:
  - [ str1, $(Take back program original manufacturer) ]
  - [ str2, YES ]
```

## Complete YARRRML document

The complete YARRRML document (also available as [example-data/x-domain/lindner/tutorial_getting_started.yml](example-data/x-domain/lindner/tutorial_getting_started.yml)) is

```yaml
prefixes:
  ceon-product: http://w3id.org/CEON/ontology/product/
  ceon-quantity: http://w3id.org/CEON/ontology/quantity/
  construction: http://w3id.org/CEON/demo/construction/
  e: http://myontology.com/
  ex: http://example.com/
  grel: http://users.ugent.be/~bjdmeest/function/grel.ttl#
  idlab-fn: https://w3id.org/imec/idlab/function#
  qudt: http://qudt.org/schema/qudt/
  qudt-quantitykind: http://qudt.org/vocab/quantitykind/
  qudt-unit: http://qudt.org/vocab/unit/

mappings:
  products:
    graphs: ex:Products
    sources:
      - [tutorial_products.csv~csv]
    s: ex:$(Product_id)
    po:
      - [ a, ceon-product:Product~iri ]
      - [ rdfs:label, $(Product Name) ]
      - p: construction:hasTakeBackProgramFromOriginalManufacturer
        o:
          function: equal
          parameters:
            - [ str1, $(Take back program original manufacturer) ]
            - [ str2, YES ]
          datatype: xsd:boolean
      - [ e:minimumStockCount, $(Minimum stock count), xsd:integer ]
      - [ e:hasProductDescription, $(Product description), en~lang ]
      - p: ceon-quantity:hasLength
        o:
          mapping: length
          condition:
            function: equal
            parameters:
              - [str1, $(Product_id), s]
              - [str2, $(Measured_product), o]
        g: ex:Dimensions
  length:
    graphs: ex:Dimensions
    sources:
      - ['tutorial_products_dimensions.csv~csv']
    s:
      value: ex:$(Measured_product)-length
    po:
      - [ a, [ceon-quantity:Length~iri, qudt:QuantityValue~iri ] ]
      - [ qudt:numericValue, $(Length), xsd:double ]
      - [ qudt:hasUnit, qudt-unit:MilliM~iri ]
```

To tryout, execute:

```bash
# result serialized as nquads:
./map.sh example-data/x-domain/lindner/tutorial_getting_started.yml
# result serialized as turtle:
./map.sh example-data/x-domain/lindner/tutorial_getting_started.yml turtle
```

## Other data formats

Besides CSV, it is also possible to generate Linked Data from existing data sources in the JSON and XML format.

### JSON

Consider the following JSON file called "[tutorial_products_dimensions.json](example-data/x-domain/lindner/tutorial_products_dimensions.json)" that
represents the dimension data instead of a CSV file:

```json
{
  "dimensions": [
    {
      "Measured_product": "Nortec_1234",
      "Length": "600",
      "Width": "600",
      "Height": "45"
    },
    {
      "Measured_product": "pedestal_1234",
      "Length": "600",
      "Width": "600",
      "Height": "2000"
    }
  ]
}
```

In the case of CSV, we considered every row as an entity.
However, in the case of JSON we need to specify what represents an entity.
This is done via the iterator,
which in this example is `$.dimensions[*]`, as we want to iterate over every object inside the array `dimensions`.
The corresponding rules (here shown for `length`) are:

```yaml
mappings:
  length:
    sources:
      - access: tutorial_products_dimensions.json
        referenceFormulation: jsonpath
        iterator: "$.dimensions[*]"
```

Here, we can also use a shortcut version:

```yaml
mappings:
  length:
    sources:
      - [ tutorial_products_dimensions.json~jsonpath, "$.dimensions[*]" ]
```

A second element is added to the array, which is the iterator.
Note that in this case we use the [JSONPath syntax](http://goessner.net/articles/JsonPath/) to
define the iterator (hence the `~jsonpath`-part).
The same syntax will be used to refer to the different values inside the objects.

### XML

Consider the following XML file called "[tutorial_products_dimensions.xml](example-data/x-domain/lindner/tutorial_products_dimensions.xml)" that
represents the dimension data instead of a CSV file:

```xml
<dimensions>
  <dimension>
    <Measured_product>Nortec_1234</Measured_product>
    <Length>600</Length>
    <Width>600</Width>
    <Height>45</Height>
  </dimension>
  <dimension>
    <Measured_product>pedestal_1234</Measured_product>
    <Length>600</Length>
    <Width>600</Width>
    <Height>2000</Height>
  </dimension>
</dimensions>
```

Similar to the JSON, we define the iterator for an XML file.
This time by using the [XPath syntax](https://www.w3.org/TR/xpath/).
The corresponding rules are:

```yaml
mappings:
  length:
    sources:
      - [ tutorial_products_dimensions.xml~xpath, /dimensions/dimension ]
```

## Wrapping up

Congratulations!
You have created your own YARRRML rules that:

* generate RDF from data about products and episodes,
* use data in CSV, JSON, and XML files,
* add triples to graphs,
* link entities, and
* transform data.

Nice work!
We hope you now feel like you have a decent grasp on how YARRRML works.

## More information

You can find more information in the following:

* [YARRRML specification](https://w3id.org/yarrrml/spec)
* [YARRRML website](https://w3id.org/yarrrml)
* [YAML specification](http://yaml.org/spec/)
