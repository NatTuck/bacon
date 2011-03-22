
namespace Bacon {

static Runtime* Bacon_Runtime_instance = 0;

Runtime*
Runtime::instance()
{
    if (!Bacon_Runtime_instance) {
        Bacon_Runtime_instance = new Bacon::Runtime;
    }

    return Bacon_Runtime_instance;
}

Runtime::Runtime()
{
    // todo: add perlembed stuff here

}


} // namespace Bacon
