# Mapping tutorial

Welcome to this Onto-DESIDE specific tutorial on mapping with [YARRRML](https://rml.io/yarrrml/).

This tutorial is illustrated with Onto-DESIDE project example data, available from the [Open Circularity Platform](https://github.com/KNowledgeOnWebScale/open-circularity-platform).

If you just want to read content, visit in this order:

* [Getting started](./getting-started.md)
* [Using targets](./using-targets.md)

If you want to try out yourself some of the mappings in above content, continue below.

## The working environment

We provide:

* A guided installation method to provide you with [YARRRML parser](https://github.com/RMLio/yarrrml-parser) and [RMLMapper](https://github.com/RMLio/rmlmapper-java) tools,
  both to run on your local computer.
* A partial copy of the example data from the [Open Circularity Platform](https://github.com/KNowledgeOnWebScale/open-circularity-platform).
* A [Solid Community Server (CSS)](https://github.com/CommunitySolidServer/CommunitySolidServer) server instance, running on you local computer.
  This CSS comes preloaded with all the actors of the **Cross-domain evalution 2025** use case.

Note that compared to the online Open Circularity Platform,
all URI's of the format `https://onto-deside.ilabt.imec.be/css12/<etc>` are replaced here with `http://localhost:3012/<etc>`.

Also note that you will be able to look inside the data on the CSS at `./local-run/data/css12`.

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
./map.sh <yarrrml-file-with-relative-path>
```

Example:

```bash
./map.sh example-data/x-domain/lindner/mapping-1.yml
```

You'll find the output files at locations as specified in the YARRRML file,
in directories relative to the path of the YARRRML file.
For the example, they are in `example-data/x-domain/lindner/`.
By convention, we give example YARRRML files local output files the extension `.testout`.
If your YARRRML file specifies output directories, make sure the directories exist before executing.

#### HTTP output

If you want to execute our example mapping writing to web resources, proceed as follows.

```bash
# start our supporting CSS; clean start (no history)
./start-css.sh
```

Now execute a mapping:

```bash
./map.sh <yarrrml-file-with-relative-path>
```

Example:

```bash
./map.sh example-data/x-domain/lindner/mapping-2.yml
```

The output is written to a URL `http://localhost:3012/<etc>`, which is in our supporting CSS.
The supporting CSS is configured so that you can view the web resources as files on your filesystem.
For the example, they are in `local-run/data/css12/lindner/ceon`.

When you're finished, you can stop the CSS as follows:

```bash
./stop-csss.sh
```

If at some later time you want to restart the CSS with the result of your previous work still there, execute:

```bash
# restart our supporting CSS; with history
./start-csss.sh -r
```
