# Mapping tutorial

Welcome to this Onto-DESIDE specific tutorial on mapping with [YARRRML](https://rml.io/yarrrml/).

The added value of this tutorial compared to the tutorials available from the [YARRRML website](https://rml.io/yarrrml/)
is that here we illustrate with Onto-DESIDE project example data, available from the [Open Circularity Platform](https://github.com/KNowledgeOnWebScale/open-circularity-platform).

If you just want to read content, visit the parts of this tutorial in this order:

* [Getting started](./getting-started.md)
* [Using targets](./using-targets.md)
* [Using linked HTTP request targets](./using-linked-http-request-targets.md)

If you want to try out yourself some of the mappings in above content, continue below.

See also the 

## The working environment

We provide:

* A guided installation method to provide you with [YARRRML parser](https://github.com/RMLio/yarrrml-parser) and [RMLMapper](https://github.com/RMLio/rmlmapper-java) tools,
  both to run on your local computer.
* A partial copy of the example data from the [Open Circularity Platform](https://github.com/KNowledgeOnWebScale/open-circularity-platform).
* A [Community Solid Server (CSS)](https://github.com/CommunitySolidServer/CommunitySolidServer) server instance, running on your local computer.

### About the example data

From the [Open Circularity Platform](https://github.com/KNowledgeOnWebScale/open-circularity-platform), we kept
**the Lindner data from the Cross-domain evalution 2025**. It is in directory `example-data/x-domain/lindner`.

We also kept the original mapping file [mapping.yml](example-data/x-domain/lindner/mapping.yml) in that directory for your reference,
but we do not use it in the tutorial here.

Note that compared to the online Open Circularity Platform,
all URI's of the format `https://onto-deside.ilabt.imec.be/css12/<etc>` are replaced here with `http://localhost:3012/<etc>`.

We added new mapping files for the tutorial. We'll meet them one by one while walking through the tutorial.
They all have file names matching `example-data/x-domain/lindner/tutorial_*.yml`.

For didactical reasons, we simplified some Lindner data and added some imaginary data.
All data files used in the mappings files of the tutorial have file names matching `example-data/x-domain/lindner/tutorial_*.csv`.

### About the data on the CSS

The CSS comes preloaded with:

* the profile of the **Lindner** actor (email: `lindner@example.com`) of the **Cross-domain evalution 2025** use case;
* some `README` data resources, available for debugging purposes.

Resources on a Solid pod are meant to be accessed through the web.
However, we set up our CSS for easy testing and debugging and made its resources
visible on the local file system in the `./local-run/data/css12` subdirectory.
This directory will appear when the CSS is running.

### Prerequisites

* a bash shell in a Linux environment
* [Node](https://nodejs.org) >= 18 with npm
* A recent Java version, for example openjdk version "17.0.10"

### Installation

Start by cloning this repository to some directory on your system, from here on simply called `the project root directory`.

All (bash) scripts mentioned here and below should be executed in the project root directory.

Execute:

```bash
npm install
npx download-rmlmapper -g v7.3.3 -f rmlmapper.jar
```

### Usage

#### Local output

To execute a mapping whose output consists of local files only, execute:

```bash
./map.sh <yarrrml-file-with-relative-path> <serialization-default-nquads>
```

Example:

```bash
# result serialized as nquads:
./map.sh example-data/x-domain/lindner/tutorial_getting_started.yml
# result serialized as turtle:
./map.sh example-data/x-domain/lindner/tutorial_getting_started.yml turtle
```

You'll find the output files of the RMLMapper at locations as specified in the YARRRML file,
in directories relative to the path of the YARRRML file.
For example, if the YARRRML file is in `example-data/x-domain/lindner`
and an output directory `out` is specified,
the output files will go to `example-data/x-domain/lindner/out`.

#### HTTP output

If you want to execute our example mappings that write to web resources, proceed as follows.

```bash
# start our supporting CSS; clean start (no history)
./start-css.sh
```

Now execute a mapping:

```bash
# no need to specify serialization when writing to web resources
./map.sh <yarrrml-file-with-relative-path>
```

Example:

```bash
./map.sh example-data/x-domain/lindner/tutorial_targets_web.yml
```

The output is written to a URL `http://localhost:3012/<etc>`, which is in our supporting CSS.

When you're finished, you can stop the CSS as follows:

```bash
./stop-css.sh
```

If at some later time you want to restart the CSS with the result of your previous work still there, execute:

```bash
# restart our supporting CSS; with history
./start-css.sh -r
```
