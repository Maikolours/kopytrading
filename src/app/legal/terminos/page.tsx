import Link from "next/link";

export default function TerminosPage() {
    return (
        <div className="min-h-screen pt-28 pb-20 px-4 sm:px-6 lg:px-8">
            <div className="max-w-3xl mx-auto">
                <Link href="/" className="text-brand-light hover:text-white text-sm flex items-center gap-2 mb-8 group">
                    <span className="group-hover:-translate-x-1 transition-transform">←</span> Inicio
                </Link>
                <h1 className="text-3xl font-bold text-white mb-8">Términos y Condiciones de Uso</h1>
                <div className="glass-card border border-white/10 rounded-2xl p-8 space-y-8 text-text-muted text-sm leading-relaxed">

                    <section>
                        <h2 className="text-white font-semibold text-base mb-2">1. Aceptación de los Términos</h2>
                        <p>Al acceder a KOPYTRADE y adquirir cualquiera de nuestros productos digitales, aceptas en su totalidad los presentes Términos y Condiciones. Si no estás de acuerdo con alguno de ellos, te rogamos que no uses nuestros servicios.</p>
                    </section>

                    <section>
                        <h2 className="text-white font-semibold text-base mb-2">2. Naturaleza del Producto</h2>
                        <p>Los archivos vendidos en KOPYTRADE son software de algoritmos de trading en formato MQL5 (.mq5), diseñados para ejecutarse en la plataforma MetaTrader 5. Son <strong className="text-white">productos digitales de descarga inmediata</strong>. Una vez descargado el archivo, no existe posibilidad de devolución o reembolso al tratarse de un bien digital intangible.</p>
                    </section>

                    <section>
                        <h2 className="text-white font-semibold text-base mb-2">3. Licencia de Uso</h2>
                        <p>Al adquirir un bot de KOPYTRADE, se te concede una licencia de uso personal, intransferible y no exclusiva, limitada a:</p>
                        <ul className="list-disc list-inside mt-2 space-y-1">
                            <li>Una cuenta Demo de MetaTrader 5</li>
                            <li>Una cuenta Real de MetaTrader 5</li>
                        </ul>
                        <p className="mt-2">Queda expresamente prohibido: redistribuir el archivo, venderlo a terceros, compartirlo, descompilarlo, modificar el código para su redistribución, o usarlo en cuentas no autorizadas.</p>
                    </section>

                    <section>
                        <h2 className="text-white font-semibold text-base mb-2">4. Limitación de Responsabilidad</h2>
                        <p>KOPYTRADE no garantiza resultados financieros con el uso de sus productos. En ningún caso KOPYTRADE será responsable de pérdidas, daños o perjuicios económicos derivados del uso del software, incluyendo pero no limitándose a pérdidas de capital en operaciones de trading.</p>
                    </section>

                    <section>
                        <h2 className="text-white font-semibold text-base mb-2">5. Política de No Devolución</h2>
                        <p>Dada la naturaleza digital e inmaterial del producto, una vez realizada la descarga del archivo, no se realizarán devoluciones ni reembolsos. En caso de problemas técnicos con la descarga, el usuario deberá contactar con soporte en un plazo máximo de 48 horas tras la compra.</p>
                    </section>

                    <section>
                        <h2 className="text-white font-semibold text-base mb-2">6. Actualizaciones</h2>
                        <p>KOPYTRADE se reserva el derecho de actualizar los bots adquiridos para mejorar su funcionamiento o adaptarlos a cambios en las plataformas de trading, sin cargo adicional para los compradores.</p>
                    </section>

                    <section>
                        <h2 className="text-white font-semibold text-base mb-2">7. Ley Aplicable y Jurisdicción</h2>
                        <p>Los presentes términos se rigen por la legislación española. Para cualquier controversia derivada del uso de KOPYTRADE, ambas partes se someten a los Juzgados y Tribunales correspondientes conforme a la normativa de comercio electrónico española.</p>
                    </section>

                    <p className="text-xs text-text-muted/60 border-t border-white/10 pt-4">Última actualización: Febrero 2026</p>
                </div>
            </div>
        </div>
    );
}
