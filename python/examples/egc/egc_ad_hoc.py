import regex

class EGCParser:

  IdentifierRegex = regex.compile(r"[A-Za-z][A-Za-z0-9_]*")
  DescriptionRegex = regex.compile(r"[A-Za-z][A-Za-z0-9_,.:;\-+=\(\) ]*")
  OntologyTermRegex = regex.compile(r"\S+")

  HexCharRegexStr = r"[0-9a-fA-F]"
  HexChar4Regex  = regex.compile(HexCharRegexStr + r"{4}")
  HexChar8Regex  = regex.compile(HexCharRegexStr + r"{8}")
  HexChar12Regex = regex.compile(HexCharRegexStr + r"{12}")

  UuidGroups = [HexChar8Regex,
                HexChar4Regex,
                HexChar4Regex,
                HexChar4Regex,
                HexChar12Regex]

  DataDescriptorElementCode2Datatype = {
      "i": "integer",
      "u": "unsigned integer",
      "f": "float",
      "b": "boolean"
    }

  DataDescriptorElementDatatype2Code = {v: k for k, v \
                    in DataDescriptorElementCode2Datatype.items()}

  RecordType2Code = {
      "taxon": "T",
      "phenotype": "P",
      "expectation": "E",
      "attribute_object": "A"
  }

  RecordCode2Type = {v: k for k, v in RecordType2Code.items()}

  ReferencePrefixPMID = "pmid"
  ReferencePrefixDOI = "doi"
  ReferencePrefixUUID = "uuid"

  Boolean2Code = {True: "T", False: "F"}
  Code2Boolean = {"T": True, "F": False}

  Placeholder = "."

  RelationCodes = ["=", "<", "<=", ">=", ">", "in", "notin"]

  # Helper methods

  def _reset_state(self):
    """
    Reset the information stored in the instance (current operation, record
    type, entire line or data) which is set by the public methods (encode,
    decode), in order to avoid passing this information (required for meaningful
    error messages, see _raise_err) around to each method.
    """
    self._operation = None
    self._record_type = None
    self._line = None
    self._data = None

  def _raise_err(self, msg, errtype = ValueError, keep_state = False):
    """
    Raise an error adding information stored in the instance,
    """
    err = []
    err.append(f"Error while {self._operation} {self._record_type} line")
    err.append(msg)
    if self._operation == "decoding":
      err.append(f"Line: {self._line}")
    else:
      err.append(f"Line data: {self._data}")
    raise errtype("\n".join(err))

  def _validate_field_by_regex(self, regex, fieldname, s):
    """
    Validate a field by requiring full match of a given regex
    """
    match = regex.fullmatch(s)
    if not match:
      self._raise_err(f"Invalid value for {fieldname}: '{s}'")

  def _validate_is_instance(self, data, datalbl, klass, klasslbl):
    """
    Validate that data that shall be encoded is of a given type
    """
    if not isinstance(data, klass):
      self._raise_err(f"Invalid type for {datalbl}, {klasslbl} expected\n"+\
                      f"Found {data} of type {type(data)}", TypeError)

  def _validate_is_string(self, data, lbl):
    self._validate_is_instance(data, lbl, str, "string")

  def _validate_is_int(self, data, lbl):
    self._validate_is_instance(data, lbl, int, "integer")

  def _validate_is_float(self, data, lbl):
    self._validate_is_instance(data, lbl, float, "float")

  def _validate_is_dict(self, data, lbl):
    self._validate_is_instance(data, lbl, dict, "dictionary")

  def _validate_is_list(self, data, lbl):
    self._validate_is_instance(data, lbl, list, "list")

  def _split_expect_n(self, s, delim, n, lbl,
                     msg = "Wrong number of elements in"):
    """
    Validate a field by requiring full match of a given regex
    """
    result = s.split(delim)
    if len(result) != n:
      self._raise_err(f"{msg} {lbl}: '{s}'")
    return result

  def _validate_data_keys(self, data, expected, label):
    """
    Validate the keys of a dictionary containing data which shall be encoded
    """
    self._validate_is_dict(data, label)
    keys = set(data.keys())
    if keys != expected:
      err = [f"Invalid set of entries in {label} dictionary"]
      missing = expected - keys
      if missing:
        err.append(f"Missing keys: {missing}")
      unknown = keys - expected
      if unknown:
        err.append(f"Unknown keys: {unknown}")
      self._raise_err("\n".join(err))

  def _validate_line_data_keys(self, data, expected):
    """
    Validate the keys of the line data which shall be encoded
    """
    self._validate_data_keys(data, expected, "line data")

  def _strip_prefix(self, s, pfx, lbl):
    """
    Checks that a string starts with the given prefix
    and returns the string without the prefix
    """
    if not s.startswith(pfx):
      self._raise_err(f"Wrong format for {lbl}:"+\
                       f"'{s}'")
    return s[len(pfx):]

  def _decode_opt(self, s, decoder):
    """
    Decode a field which can contain the placeholder
    """
    if s == EGCParser.Placeholder:
      return None
    else:
      return decoder(s)

  def _encode_opt(self, field_data, encoder):
    """
    Encode a field which can contain the placeholder
    """
    if field_data == None:
      return EGCParser.Placeholder
    else:
      return encoder(field_data)

  # Validation of string fields

  def _validate_identifier(self, s):
    self._validate_field_by_regex(EGCParser.IdentifierRegex, "identifier", s)

  def _validate_description(self, s):
    self._validate_field_by_regex(EGCParser.DescriptionRegex, "description", s)

  def _validate_ontology_term(self, s):
    self._validate_field_by_regex(EGCParser.OntologyTermRegex,
        "ontology term", s)

  # Decoding/encoding of single fields

  def _decode_identifier(self, s):
    self._validate_identifier(s)
    return s

  def _encode_identifier(self, data):
    self._validate_is_string(data, "identifier")
    self._validate_identifier(data)
    return data

  def _decode_opt_identifier(self, s):
    return self._decode_opt(s, self._decode_identifier)

  def _encode_opt_identifier(self, data):
    return self._encode_opt(data, self._encode_identifier)

  def _decode_description(self, data):
    self._validate_description(data)
    return data

  def _encode_description(self, data):
    self._validate_is_string(data, "description")
    self._validate_description(data)
    return data

  def _decode_opt_description(self, s):
    return self._decode_opt(s, self._decode_description)

  def _encode_opt_description(self, data):
    return self._encode_opt(data, self._encode_description)

  def _decode_ontology_term(self, s):
    self._validate_ontology_term(s)
    return s

  def _encode_ontology_term(self, data):
    self._validate_is_string(data, "ontology term")
    self._validate_ontology_term(data)
    return data

  def _decode_ontology_link(self, s):
    elems = self._split_expect_n(s, ":", 2, "ontology link")
    result = {"ontology_prefix": self._decode_identifier(elems[0]),
              "ontology_term":   self._decode_ontology_term(elems[1])}
    return result

  def _encode_ontology_link(self, data):
    self._validate_data_keys(data, {"ontology_prefix", "ontology_term"},
                             "ontology link")
    return ":".join([self._encode_identifier(data["ontology_prefix"]),
                     self._encode_ontology_term(data["ontology_term"])])

  def _decode_opt_ontology_link(self, s):
    return self._decode_opt(s, self._decode_ontology_link)

  def _encode_opt_ontology_link(self, data):
    return self._encode_opt(data, self._encode_ontology_link)

  def _decode_pubmed_id(self, s):
    s = self._strip_prefix(s, EGCParser.ReferencePrefixPMID + ":", "Pubmed ID")
    return {"type": "Pubmed ID", "id": self._decode_uint(s, "Pubmed ID")}

  def _encode_pubmed_id(self, data):
    self._validate_is_dict(data, "Pubmed ID")
    self._validate_data_keys(data, {"id", "type"}, "Pubmed ID")
    return EGCParser.ReferencePrefixPMID + ":" + \
             self._encode_uint(data["id"], "Pubmed ID")

  def _decode_doi(self, s):
    doi = self._strip_prefix(s, EGCParser.ReferencePrefixDOI + ":10.", "DOI")
    elems = self._split_expect_n(doi, r"/", 2, "DOI", "Wrong format for")
    if len(elems[0]) == 0 or len(elems[1]) == 0:
      self._raise_err(f"Wrong format for DOI: '{s}'")
    return {"type": "DOI", "registrant": elems[0], "object": elems[1]}

  def _encode_doi(self, data):
    self._validate_data_keys(data, {"type", "registrant", "object"}, "DOI")
    self._validate_is_string(data["registrant"], "DOI registrant")
    self._validate_is_string(data["object"], "DOI object")
    if len(data["registrant"]) == 0:
      self._raise_err("Wrong data for DOI (registrant is empty)")
    if len(data["object"]) == 0:
      self._raise_err("Wrong data for DOI (object is empty)")
    return EGCParser.ReferencePrefixDOI + ":10." + \
           r"/".join([data["registrant"], data["object"]])

  def _decode_uuid(self, s):
    uuid = self._strip_prefix(s, EGCParser.ReferencePrefixUUID + ":", "UUID")
    elems = self._split_expect_n(uuid, "-", 5, "UUID", "Wrong format for")
    result = {"type": "UUID"}
    for i, rgx in enumerate(EGCParser.UuidGroups):
      if not rgx.fullmatch(elems[i]):
        self._raise_err(f"Wrong format for UUID: '{s}'")
      result[f"g{i+1}"] = elems[i]
    return result

  def _encode_uuid(self, data):
    groups = ["g1", "g2", "g3", "g4", "g5"]
    self._validate_data_keys(data, set(groups) | {"type"}, "UUID")
    for i, g in enumerate(groups):
      self._validate_is_string(data[g], "UUID group")
      self._validate_field_by_regex(EGCParser.UuidGroups[i], g, data[g])
    return EGCParser.ReferencePrefixUUID + ":" +\
      "-".join([data["g1"], data["g2"], data["g3"], data["g4"], data["g5"]])

  def _decode_reference(self, s):
    result = None
    for decode in [self._decode_pubmed_id, self._decode_doi, self._decode_uuid]:
      try:
        result = decode(s)
      except ValueError:
        continue
      break
    if result is None:
      self._raise_err("Wrong format for reference.\n"+\
                      f"Not a valid Pubmed ID, DOI or UUID: '{s}'")
    return result

  def _encode_reference(self, data):
    result = None
    for encode in [self._encode_pubmed_id, self._encode_doi, self._encode_uuid]:
      try:
        result = encode(data)
      except (TypeError, ValueError):
        continue
      break
    if result is None:
      self._raise_err("Wrong data for reference.\n"+\
                      "No valid data for Pubmed ID, DOI or UUID")
    return result

  def _decode_data_descriptor_element_type(self, s):
    if s not in EGCParser.DataDescriptorElementCode2Datatype:
      self._raise_err("Invalid datatype code in data descriptor"+\
                      "element: {}".format(s))
    return EGCParser.DataDescriptorElementCode2Datatype[s]

  def _encode_data_descriptor_element_type(self, data):
    self._validate_is_string(data, "dataype in data descriptor element")
    if data not in EGCParser.DataDescriptorElementDatatype2Code:
      self._raise_err("Invalid datatype in data descriptor"+\
                      "element: {}".format(data))
    return EGCParser.DataDescriptorElementDatatype2Code[data]

  def _decode_data_descriptor_element(self, e):
    subelems = self._split_expect_n(e, ":", 3, "data descriptor element")
    return { "element": self._decode_identifier(subelems[0]),
        "datatype": self._decode_data_descriptor_element_type(subelems[1]),
        "category": self._decode_identifier(subelems[2])}

  def _encode_data_descriptor_element(self, subelems):
    self._validate_data_keys(subelems, {"element", "datatype", "category"},
                             "data descriptor element")
    return ":".join([\
        self._encode_identifier(subelems["element"]),
        self._encode_data_descriptor_element_type(subelems["datatype"]),
        self._encode_identifier(subelems["category"])])

  def _decode_data_descriptor(self, s):
    if len(s) == 0:
      self._raise_err("Data descriptor is empty")
    try:
      elems = self._split_expect_n(s, ":", 2, "data descriptor")
      return {"datatype": self._decode_data_descriptor_element_type(elems[0]),
              "category": self._decode_identifier(elems[1])}
    except ValueError:
      return [self._decode_data_descriptor_element(e) for e in s.split(",")]

  def _encode_data_descriptor(self, data):
    try:
      self._validate_data_keys(data, {"datatype", "category"},
                               "data descriptor")
      return ":".join([\
        self._encode_data_descriptor_element_type(data["datatype"]),
        self._encode_identifier(data["category"])])
    except (ValueError, TypeError):
      self._validate_is_list(data, "data descriptor")
      if len(data) == 0:
        self._raise_err("Data descriptor is empty")
    return ",".join([self._encode_data_descriptor_element(e) for e in data])

  def _decode_relation(self, s):
    if s not in EGCParser.RelationCodes:
      self._raise_err(f"Unknown relation symbol: {s}")
    return s

  def _encode_relation(self, data):
    self._validate_is_string(data, "relation symbol")
    if data not in EGCParser.RelationCodes:
      self._raise_err(f"Unknown relation symbol: {data}")
    return data

  def _decode_num(self, s, lbl):
    try:
      value = int(s)
    except ValueError:
      try:
        value = float(s)
      except ValueError:
        self._raise_err(f"Invalid non-numeric value for {lbl}: '{s}'")
    return value

  def _encode_num(self, data, lbl):
    try:
      self._validate_is_int(data, lbl)
    except TypeError:
      try:
        self._validate_is_float(data, lbl)
      except TypeError:
        self._raise_err("Invalid type for {}, ".format(lbl)+\
                        "exected int or float\n"+\
                        f"Found: {data} of type {type(data)}", TypeError)
    return str(data)

  def _decode_uint(self, s, lbl):
    try:
      value = int(s)
    except ValueError:
      self._raise_err(f"Invalid value for {lbl}, excepted int >= 0: '{s}'")
    if value < 0:
      self._raise_err(f"Invalid value for {lbl}, expected int >= 0: '{s}'")
    return value

  def _encode_uint(self, data, lbl):
    self._validate_is_int(data, lbl)
    if data < 0:
      self._raise_err(f"Invalid value for {lbl}, expected int >= 0: {data}")
    return str(data)

  def _decode_boolean(self, s, lbl):
    if s in EGCParser.Code2Boolean:
      return EGCParser.Code2Boolean[s]
    else:
      self._raise_err(f"Invalid value for {lbl}: '{s}'\n"+\
          f"expected one of: {list(EGCParser.Code2Boolean.keys())}")

  def _encode_boolean(self, data, lbl):
    for b in EGCParser.Boolean2Code:
      if data is b:
        return EGCParser.Boolean2Code[data]
    self._raise_err("Invalid type for {lbl}, expected True or False\n"+\
                    "Found: {data} of type {type(data)}", TypeError)

  def _decode_subject_ref(self, s):
    elems = self._split_expect_n(s, ":", 2, "subject reference")
    result = {"prefix": elems[0]}
    if result["prefix"] == "T":
      result["ncbi_taxid"] = self._decode_uint(elems[1], "NCBI TaxID")
    elif result["prefix"] == "P":
      result["phenotype_name"] = self._decode_identifier(elems[1])
    else:
      self._raise_err(f"Unknown prefix in subject reference: '{s}'")
    return result

  def _encode_subject_ref(self, data):
    self._validate_is_dict(data, "subject reference")
    if "prefix" in data:
      if data["prefix"] == "T":
        self._validate_data_keys(data, {"prefix", "ncbi_taxid"},
                                 "taxon subject reference")
        return "T:{}".format(self._encode_uint(data["ncbi_taxid"], "NCBI TaxID"))
      elif data["prefix"] == "P":
        self._validate_data_keys(data, {"prefix", "phenotype_name"},
                                 "phenotype subject reference")
        return "P:{}".format(self._encode_identifier(data["phenotype_name"]))
      else:
        self._raise_err("Unknown prefix in subject reference: '{}'".\
                        format(data["prefix"]))
    else:
      self._raise_err(f"Missing prefix entry in subject reference data: {data}")

  def _decode_attribute_ref(self, s):
    try:
      return self._decode_identifier(s)
    except ValueError:
      elems = self._split_expect_n(s, ".", 2, "attribute reference")
      return {"attribute": self._decode_identifier(elems[0]),
              "element": self._decode_identifier(elems[1])}

  def _encode_attribute_ref(self, data):
    try:
      return self._encode_identifier(data)
    except (ValueError, TypeError):
      self._validate_data_keys(data, {"attribute", "element"},
                               "attribute reference")
      return ".".join([self._encode_identifier(data["attribute"]),
                       self._encode_identifier(data["element"])])

  def _determine_interval_type(self, s):
    result = {}
    if ">..<" in s:
      elems = s.split(">..<")
      result["interval_type"] = "open"
    elif ">.." in s:
      elems = s.split(">..")
      result["interval_type"] = "min-open"
    elif "..<" in s:
      elems = s.split("..<")
      result["interval_type"] = "max-open"
    elif ".." in s:
      elems = s.split("..")
      result["interval_type"] = "closed"
    else:
      self._raise_err("Invalid format for interval"+\
                       f": '{s}'")
    if len(elems) != 2:
      self._raise_err("Invalid format for interval"+\
                       f": '{s}'")
    return result, elems

  def _decode_interval(self, s):
    result, elems = self._determine_interval_type(s)
    has_min_max = False
    if result["interval_type"] == "closed":
      try:
        result["min"] = int(elems[0])
        result["max"] = int(elems[1])
        has_min_max = True
      except ValueError:
        pass
    if not has_min_max:
      try:
        result["min"] = float(elems[0])
      except ValueError:
        self._raise_err("Invalid interval minimum"+\
                             ": '{}'".format(elems[0]))
      try:
        result["max"] = float(elems[1])
      except ValueError:
        self._raise_err("Invalid interval maximum"+\
                         ": '{}'".format(elems[1]))
    return result

  IntervalTypeCodes = {"open": ">..<", "min-open": ">..",
                       "max-open": "..<", "closed": ".."}

  def _encode_interval(self, data, lbl):
    self._validate_data_keys(data, {"interval_type", "min", "max"}, lbl)
    if data["interval_type"] not in EGCParser.IntervalTypeCodes:
      self._raise_err("Invalid interval type"+\
                      ": '{}'".format(data["interval_type"]))
    elif data["interval_type"] == "closed":
      try:
        self._validate_is_int(data["min"], lbl)
        self._validate_is_int(data["max"], lbl)
      except TypeError:
        try:
          self._validate_is_float(data["min"], lbl)
          self._validate_is_float(data["max"], lbl)
        except TypeError:
          self._raise_err("Wrong type for interval min/max\n"+\
                          "Expected: two int values or two float values\n"+\
                          "Found min: {} ".format(data["min"])+\
                          "of type {}; ".format(type(data["min"]))+\
                          "; max: {} ".format(data["max"])+\
                          "of type {}".format(type(data["max"])),
                          TypeError)
    else:
      self._validate_is_float(data["min"], lbl)
      self._validate_is_float(data["max"], lbl)
    return str(data["min"])+\
           EGCParser.IntervalTypeCodes[data["interval_type"]]+\
           str(data["max"])

  def _decode_expectation_value(self, s, relation):
    if relation == "=":
      try:
        return self._decode_boolean(s, "expectation value")
      except ValueError:
        try:
          return self._decode_num(s, "expectation value")
        except ValueError:
          self._raise_err(f"Invalid content of value field: {s}")
    elif relation in ["<", "<=", ">=", ">"]:
      return self._decode_num(s, "expectation value")
    else:
      assert(relation in ["in", "notin"])
      return self._decode_interval(s)

  def _encode_expectation_value(self, data, relation):
    if relation == "=":
      try:
        return self._encode_boolean(data, "expectation value")
      except (ValueError, TypeError):
        try:
          return self._encode_num(data, "expectation value")
        except (ValueError, TypeError):
          self._raise_err("Invalid value for expectation line "+\
              "value field: {}".format(data))
    elif relation in ["<", "<=", ">=", ">"]:
      return self._encode_num(data, "expectation value")
    else:
      assert(relation in ["in", "notin"])
      return self._encode_interval(data, "expectation value")

  # Decode / encode entire lines

  def _decode_expectation_line(self, line):
    elems = self._split_expect_n(line, "\t", 6, "expectation line")
    relation = self._decode_relation(elems[3])
    return {"record_type": "expectation",
            "subject": self._decode_subject_ref(elems[1]),
            "attribute": self._decode_attribute_ref(elems[2]),
            "relation": relation,
            "value": self._decode_expectation_value(elems[4], relation),
            "reference": self._decode_reference(elems[5])}

  def _encode_expectation_line(self, data):
    self._validate_line_data_keys(data, {"record_type", "subject", "attribute",
                                         "relation", "value", "reference"})
    relation = self._encode_relation(data["relation"])
    return "\t".join([EGCParser.RecordType2Code["expectation"],
             self._encode_subject_ref(data["subject"]),
             self._encode_attribute_ref(data["attribute"]),
             relation,
             self._encode_expectation_value(data["value"], relation),
             self._encode_reference(data["reference"])])

  def _decode_phenotype_line(self, line):
    elems = self._split_expect_n(line, "\t", 4, "phenotype line")
    return {"record_type": "phenotype",
            "name": self._decode_identifier(elems[1]),
            "definition": self._decode_opt_description(elems[2]),
            "ontology_link": self._decode_opt_ontology_link(elems[3])}

  def _encode_phenotype_line(self, data):
    self._validate_line_data_keys(data, {"record_type", "name", "definition",
                                         "ontology_link"})
    return "\t".join([EGCParser.RecordType2Code["phenotype"],
                self._encode_identifier(data["name"]),
                self._encode_opt_description(data["definition"]),
                self._encode_opt_ontology_link(data["ontology_link"])])

  def _decode_attribute_line(self, line):
    elems = self._split_expect_n(line, "\t", 5, "attribute object line")
    return {"record_type": "attribute_object",
            "name": self._decode_identifier(elems[1]),
            "ontology_link": self._decode_ontology_link(elems[2]),
            "data_descriptor": self._decode_data_descriptor(elems[3]),
            "group_name": self._decode_opt_identifier(elems[4])}

  def _encode_attribute_line(self, data):
    self._validate_line_data_keys(data, {"record_type", "name", "ontology_link",
                                         "data_descriptor", "group_name"})
    return "\t".join([EGCParser.RecordType2Code["attribute_object"],
                self._encode_identifier(data["name"]),
                self._encode_opt_ontology_link(data["ontology_link"]),
                self._encode_data_descriptor(data["data_descriptor"]),
                self._encode_opt_identifier(data["group_name"])])

  def _decode_taxon_line(self, line):
    elems = self._split_expect_n(line, "\t", 3, "taxon line")
    return {"record_type": "taxon",
            "name": self._decode_description(elems[1]),
            "ncbi_taxid": self._decode_uint(elems[2], "NCBI TaxID")}

  def _encode_taxon_line(self, data):
    self._validate_line_data_keys(data, {"record_type", "name", "ncbi_taxid"})
    return "\t".join([self.RecordType2Code["taxon"],
                      self._encode_description(data["name"]),
                      self._encode_uint(data["ncbi_taxid"], "NCBI TaxID")])

  # Public methods for decoding/encoding

  def decode(self, line):
    self._operation = "decoding"
    line = line.rstrip("\n")
    self._line = line
    try:
      if line.startswith("#"):
        result = line
      elif line.startswith(EGCParser.RecordType2Code["taxon"] + "\t"):
        self._record_type = "taxon"
        result = self._decode_taxon_line(line)
      elif line.startswith(EGCParser.RecordType2Code["phenotype"] + "\t"):
        self._record_type = "phenotype"
        result = self._decode_phenotype_line(line)
      elif line.startswith(EGCParser.RecordType2Code["expectation"] + "\t"):
        self._record_type = "expectation"
        result = self._decode_expectation_line(line)
      elif line.startswith(EGCParser.RecordType2Code["attribute_object"] + "\t"):
        self._record_type = "attribute object"
        result = self._decode_attribute_line(line)
      else:
        self._record_type = "input"
        self._raise_err("Unknown record type")
    finally:
      self._reset_state()
    return result

  def encode(self, data):
    self._operation = "encoding"
    self._data = data
    self._record_type = "input"
    try:
      if isinstance(data, str):
        self._record_type = "comment"
        if data[0] == "#":
          result = data
        else:
          self._raise_err(f"Invalid content of data: '{data}'\n"+\
              "Strings should start with '#' and are"+\
              "handled as comments.")
      else:
        self._validate_is_dict(data, "record")
        if not "record_type" in data:
          self._raise_err("Missing record type in line data")
        if data["record_type"] == "taxon":
          self._record_type = "taxon"
          result = self._encode_taxon_line(data)
        elif data["record_type"] == "phenotype":
          self._record_type = "phenotype"
          result = self._encode_phenotype_line(data)
        elif data["record_type"] == "expectation":
          self._record_type = "expectation"
          result = self._encode_expectation_line(data)
        elif data["record_type"] == "attribute_object":
          self._record_type = "attribute object"
          result = self._encode_attribute_line(data)
        else:
          self._raise_err("Unknown record type for line data"+\
                          ": {}".format(data["record_type"]))
    finally:
      self._reset_state()
    return result
