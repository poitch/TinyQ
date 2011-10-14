# TinyQ

Simple message broker that uses JSON based protocol

## Overview

TinyQ is built on the notion of buckets and funnels. A client drops messages into a bucket, and buckets can be fed to funnels, from which clients can consume messages.

All configurations are supported, one-to-one, one-to-many, many-to-one and many-to-many.

Before consuming from a Funnel, it has to be fed from a bucket first.

## Protocol

Commands are objects in JSON format. Commands are delimited by a null character.

When sending a command the *Command* attribute is required.

The different action possible are: *PutMessages*, *FeedFunnel*, *GetMessages*

### Example

```JSON
{"Command": "PutMessages", "Bucket": "InputA", "Message": {"Foo": "Bar"}}

{"Command": "FeedFunnel", "Bucket": "InputA", "Funnel": "OutputA"}

{"Command": "GetMessages", "Funnel": "OutputA"}
```






