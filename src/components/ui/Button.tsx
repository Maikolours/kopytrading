import React from 'react';

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
    variant?: 'primary' | 'outline' | 'glass' | 'accent' | 'danger';
    size?: 'sm' | 'md' | 'lg';
    fullWidth?: boolean;
    loading?: boolean;
}

export const Button: React.FC<ButtonProps> = ({
    children,
    variant = 'primary',
    size = 'md',
    fullWidth = false,
    loading = false,
    className = '',
    disabled,
    ...props
}) => {
    const baseStyles = "inline-flex items-center justify-center font-medium transition-all duration-300 rounded-full focus:outline-none focus:ring-2 focus:ring-brand-light focus:ring-offset-2 focus:ring-offset-bg-dark disabled:opacity-50 disabled:cursor-not-allowed";

    const variants = {
        primary: "bg-gradient-to-r from-brand to-brand-bright text-white hover:from-brand-light hover:to-brand hover:shadow-[0_0_35px_rgba(168,85,247,0.4)] hover:-translate-y-1 hover:scale-105 active:scale-100 border border-transparent",
        accent: "bg-gradient-to-r from-accent to-accent-light text-black font-bold hover:from-accent-light hover:to-accent hover:shadow-[0_0_35px_rgba(245,158,11,0.4)] hover:-translate-y-1 hover:scale-105 active:scale-100 border border-transparent",
        outline: "bg-transparent text-brand-light border-2 border-brand-bright hover:bg-brand hover:text-white hover:shadow-[0_0_25px_rgba(168,85,247,0.3)] hover:-translate-y-0.5",
        glass: "bg-surface/40 backdrop-blur-md text-white border border-white/20 hover:bg-brand/20 hover:border-brand-light/60 hover:shadow-[0_0_20px_rgba(168,85,247,0.2)] hover:-translate-y-0.5",
        danger: "bg-gradient-to-r from-danger to-red-500 text-white hover:from-red-500 hover:to-danger shadow-lg shadow-danger/20 hover:-translate-y-0.5"
    };

    const sizes = {
        sm: "px-4 py-2 text-sm",
        md: "px-6 py-3 text-base",
        lg: "px-8 py-4 text-lg"
    };

    const widthClass = fullWidth ? "w-full" : "";

    return (
        <button
            className={`${baseStyles} ${variants[variant]} ${sizes[size]} ${widthClass} ${className}`}
            disabled={disabled || loading}
            {...props}
        >
            {loading && (
                <svg className="animate-spin -ml-1 mr-3 h-4 w-4 text-current" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
            )}
            {children}
        </button>
    );
};
