#ifndef BACON_RUNTIME_HH
#define BACON_RUNTIME_HH

namespace Bacon {

class Runtime {
  public:
    static Runtime* instance();

    void load_perl(char* source_fn);

  private:
    Runtime();
    ~Runtime();
};

} // namespace Bacon

#endif
