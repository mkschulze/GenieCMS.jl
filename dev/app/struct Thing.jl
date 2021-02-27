struct Thing
  super::Concept
  _inferred
  _type
  Thing(grpc_concept) = new(Concept(grpc_concept),
    grpc_concept.inferred_res.inferred,
    grakn.service.Session.Concept.ConceptFactory.create_local_concept(grpc_concept.type_res.type))
end
is_inferred(t::Thing) = t._inferred
type(t::Thing) = t._type



class Thing(Concept):

    def __init__(self, grpc_concept):
        super(Thing, self).__init__(grpc_concept)
        self._inferred = grpc_concept.inferred_res.inferred
        from grakn.service.Session.Concept import ConceptFactory
        self._type = ConceptFactory.create_local_concept(grpc_concept.type_res.type)

    def is_inferred(self):
        return self._inferred

    def type(self):
        return self._type