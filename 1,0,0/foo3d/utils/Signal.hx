package foo3D.utils;

class Signal<T> {

	var m_listener:List < T->Void >;

	public function new() {
		m_listener = new List < T->Void >();
	}
	
	public function add(_func:T->Void):Void	{
		for (l in m_listener) {
			if (Reflect.compareMethods(l, _func)) {
				throw "NO DOUBLE ADD";
				return; // no double add!
			}
		}
		m_listener.push(_func);
	}
	
	public function remove(_func:T->Void):Void {
		for (f in m_listener) {
			if (Reflect.compareMethods(f, _func)) {
				if (m_listener.remove(f) == false)
					throw "WTF?";
				break;
			}
		}
	}
	
	public function has(_func:T->Void):Bool {
		var found:Bool = false;
		for (l in m_listener) {
			if (Reflect.compareMethods(l, _func)) {
				found = true;
				break;				
			}
		}
		return found;
	}
	
	public function dispatch(?_data:T):Void {
		for (l in m_listener)
			l(_data);
	}
}