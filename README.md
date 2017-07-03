# pascal2xml
Set of classes to serialize pascal objects to/from xml. Compatible with Delphi and Lazarus.

1. The project ObjectsXMLStreaming.lpi is an example of use this library. Just open it in Lazarus and run. There are no output. You need to debug main procedure to follow the steps to convert an object to a XML and a XML to an object:

Some considerations:

1. To instantiate an object from a xml, this xml needs to be created by class TObjectToXML. You need to implement a TXMLToObject.OnCreateObject event to do it. 


It's possible to use in Delphi, with some changes. I'll post it in the future.
