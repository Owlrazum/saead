fn main() {
    uniffi::generate_scaffolding("./src/saead.udl").unwrap();
}