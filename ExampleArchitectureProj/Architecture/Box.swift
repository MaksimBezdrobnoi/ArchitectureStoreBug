internal final class Box<Wrapped> {
    var wrappedValue: Wrapped

    init(wrappedValue: Wrapped) {
        self.wrappedValue = wrappedValue
    }

    var boxedValue: Wrapped {
        _read { yield wrappedValue }
        _modify { yield &wrappedValue }
    }
}
