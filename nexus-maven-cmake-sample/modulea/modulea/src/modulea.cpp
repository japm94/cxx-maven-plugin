#include <modulea/modulea.h>

#include <moduleb/moduleb.h>

#include <QString>

moduleA::moduleA()
{

}

moduleA::~moduleA()
{

}

QString moduleA::getValue() const
{
    return "module A value";
}

QString moduleA::getValueFromModuleB() const
{
    return ModuleB().getValue();
}
