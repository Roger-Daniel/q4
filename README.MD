# q4 — 4D Compatibility Library for FreePascal/Lazarus

### Project status

q4 is under development and is not yet ready for standalone use.

This repository currently contains the compatibility library. Instructions and examples for creating and initializing a database are not yet included.

A standalone example using a small database schema will be added to demonstrate how to get started.

## Overview

### What is 4D?

[4D](https://www.4d.com/) (formerly *4th Dimension*) is an application development environment and relational database management system introduced in the 1980s.

It combines a programming language, a database engine, and development tools, particularly suited to building business applications.

### What is q4?

**q4** is an open-source library developed in **FreePascal/Lazarus**, designed to reproduce part of the functionality and behavior of the 4D environment.

Its main goal is to facilitate the migration of existing 4D applications to FreePascal/Lazarus while preserving, as much as possible, the concepts, mechanisms, and behavior of the original language.

q4 uses **SQLite** as its database engine.

## Features

The library provides functionality including:

- **Records**: creation, loading, modification, and deletion.
- **Selections**: management of current and named selections, navigation, and manipulation of record sets.
- **Queries and sorting**: implementation of 4D-like querying and sorting behavior.
- **Transactions**: committing and rolling back changes.
- **Strings**: UTF-8 string manipulation functions.
- **Arrays**: array handling with 1-based indexing, consistent with 4D behavior.
- **Objects and collections**: creation and manipulation functions.
- **Processes**: management of independent execution contexts.

The library is under active development and does not implement the full functionality of 4D.

## Project Philosophy

q4 is not intended to reproduce the 4D development environment or its graphical user interface.

Instead, the project focuses on providing a compatibility layer that allows existing 4D application logic and business processes to be adapted to FreePascal/Lazarus.

Compatibility is primarily based on reproducing observable behavior rather than internal implementation details.

## Project Independence

**q4 is an independent project and is not affiliated with 4D.**

References to 4D commands, features, and official documentation are provided solely for documentation, compatibility, and interoperability purposes.

4D is a trademark of its respective owner.

Official website: https://www.4d.com/