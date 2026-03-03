import React from 'react';

interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
    children: React.ReactNode;
    interactive?: boolean;
}

export const Card: React.FC<CardProps> = ({ children, className = '', interactive = false, ...props }) => {
    const baseStyles = "glass-card p-6 overflow-hidden relative transition-all duration-500";
    const interactiveStyles = interactive ? "hover:shadow-[0_20px_40px_rgba(0,0,0,0.8),_0_0_30px_rgba(139,92,246,0.3)] hover:-translate-y-2 hover:scale-[1.02] hover:border-brand-light/50 z-10 hover:z-20 origin-center" : "";

    return (
        <div className={`${baseStyles} ${interactiveStyles} ${className}`} {...props}>
            <div className="absolute inset-0 bg-gradient-to-br from-white/5 to-transparent opacity-0 hover:opacity-100 transition-opacity duration-500 pointer-events-none"></div>
            {children}
        </div>
    );
};

export const CardHeader: React.FC<React.HTMLAttributes<HTMLDivElement>> = ({ children, className = '', ...props }) => (
    <div className={`mb-4 pb-4 border-b border-white/5 ${className}`} {...props}>
        {children}
    </div>
);

export const CardTitle: React.FC<React.HTMLAttributes<HTMLHeadingElement>> = ({ children, className = '', ...props }) => (
    <h3 className={`text-xl font-semibold text-white ${className}`} {...props}>
        {children}
    </h3>
);

export const CardContent: React.FC<React.HTMLAttributes<HTMLDivElement>> = ({ children, className = '', ...props }) => (
    <div className={`space-y-4 ${className}`} {...props}>
        {children}
    </div>
);

export const CardFooter: React.FC<React.HTMLAttributes<HTMLDivElement>> = ({ children, className = '', ...props }) => (
    <div className={`mt-6 pt-4 border-t border-white/5 flex items-center ${className}`} {...props}>
        {children}
    </div>
);
